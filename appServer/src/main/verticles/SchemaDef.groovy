import java.security.MessageDigest
import io.vertx.core.json.JsonObject
import io.vertx.groovy.ext.jdbc.JDBCClient
import java.util.regex.Pattern

class SchemaDef {
    private def vertx

    SchemaDef(vertx) {
        this.vertx = vertx;
    }

    def processCreateRequest(content, fn) {
        assert content.db_type_id && content.db_type_id instanceof Integer
        assert content.ddl.size() <= 8000

        def md5hash = this.getMD5(content.ddl, content.statement_separator)

        if (!content.statement_separator) {
            content.statement_separator = ";"
        }

        // see if we can find an existing schema that matches this md5 and db_type
        DatabaseClient.singleRead(this.vertx, """
            SELECT
                d.id as db_type_id,
                d.simple_name,
                d.full_name,
                d.context,
                d.batch_separator,
                s.id as schema_def_id,
                s.short_code,
                s.structure_json
            FROM
                db_types d
                    LEFT OUTER JOIN schema_defs s ON
                        d.id = s.db_type_id AND
                        s.md5 = ?
            WHERE
                d.id = ?
            """,
            [ md5hash, content.db_type_id ],
            { dbDetails ->
                if (dbDetails == null) {
                    throw new Exception("Unable to find database type details");
                }

                // schema_def already registered, return it
                if (dbDetails.short_code != null) {
                    fn([
                        _id: "${content.db_type_id}_${dbDetails.short_code}".toString(),
                        short_code: dbDetails.short_code,
                        schema_structure: dbDetails.structure_json != null ?
                            new JsonObject(dbDetails.structure_json) : null
                    ])
                } else {
                    this.registerSchema(content, md5hash, dbDetails, fn)
                }
            }
        )
    }

    private String getMD5(ddl, statement_separator) {
        def digest = MessageDigest.getInstance("MD5")
        return new BigInteger(
            1, digest.digest( (statement_separator + ddl).getBytes() )
        ).toString(16).padLeft(32,"0")
    }


    private def getUniqueShortCode(db_type_id, md5hash, fn) {
        def short_code = md5hash.substring(0,5)

        DatabaseClient.getConnection(this.vertx, {connection ->
            connection.queryWithParams("""
            SELECT
                short_code
            FROM
                schema_defs s
            WHERE
                s.db_type_id = ? AND
                s.short_code LIKE ?
            """, [db_type_id, short_code + "%"], { possibleConflicts ->
                connection.close()
                def foundUniqueCode = false
                while (!foundUniqueCode) {
                    // look through each of the possible conflicts to see if the
                    // current short code already exists
                    if (possibleConflicts.result().results.inject(false) { result, row ->
                            result || row[0] == short_code
                        }) {
                        // if it does already exist, then make the short_code one
                        // character bigger and see if that is available
                        short_code = md5hash.substring(0,short_code.size()+1)
                        // we assume that eventually the md5 will have a unique
                        // combination of characters to use as the short_code
                    } else {
                        foundUniqueCode = true;
                    }
                }
                fn(short_code)
            })
        })

    }

    private def create(createAttributes, fn) {
        DatabaseClient.getConnection(this.vertx, {connection ->
            connection.updateWithParams("""
            INSERT INTO
                schema_defs
            (
                db_type_id,
                short_code,
                ddl,
                md5,
                statement_separator,
                structure_json,
                last_used
            )
            VALUES (?,?,?,?,?,?,current_timestamp)
            """, [
                createAttributes.db_type_id,
                createAttributes.short_code,
                createAttributes.ddl,
                createAttributes.md5,
                createAttributes.statement_separator,
                null
                //structure != null ? (new JsonBuilder(structure).toString()) : null
            ], {
                connection.close()
                if (it.succeeded()) {
                    fn(it.result())
                } else {
                    println it.cause().getMessage()
                }
            })
        })
    }

    private def registerSchema(content, md5hash, dbDetails, fn) {

        this.getUniqueShortCode(content.db_type_id, md5hash, { short_code ->
            // if the dbType context is "host", then we have to try to create the database in our
            // backend environment before we try to save the schema definition
            if (dbDetails.context == "host") {
                this.buildRunningDatabase(
                dbDetails,
                short_code,
                content.ddl,
                content.statement_separator,
                {
                    this.create([
                        "db_type_id": content.db_type_id,
                        "short_code": short_code,
                        "md5": md5hash,
                        "ddl": content.ddl,
                        "statement_separator": content.statement_separator,
                        "structure": null
                    ], { result ->
                        fn([
                            _id: "${content.db_type_id}_${short_code}".toString(),
                            short_code: short_code
                        ])
                    })
                })
            } else { // context is not in our backend, so don't need to attempt to build it first
                this.create([
                    "db_type_id": content.db_type_id,
                    "short_code": short_code,
                    "md5": md5hash,
                    "ddl": content.ddl,
                    "statement_separator": content.statement_separator,
                    "structure": null
                ], { result ->
                    fn([
                        _id: "${content.db_type_id}_${short_code}".toString(),
                        short_code: short_code
                    ])
                })
            }
        })
    }

    private def findAvailableHost(db_type_id, fn) {
        DatabaseClient.singleRead(this.vertx, """
            SELECT
                h.id,
                h.db_type_id,
                h.jdbc_url_template,
                h.default_database,
                h.admin_username,
                h.admin_password,
                d.setup_script_template,
                d.drop_script_template,
                d.batch_separator,
                d.jdbc_class_name
            FROM
                Hosts h
                    INNER JOIN db_types d ON
                        h.db_type_id = d.id
            WHERE
                h.db_type_id = ? AND
                not exists (
                    SELECT
                        1
                    FROM
                        Hosts h2
                    WHERE
                        h2.id != h.id AND
                        h2.db_type_id = h.db_type_id AND
                        coalesce((SELECT count(s.id) FROM schema_defs s WHERE s.current_host_id = h2.id), 0) <
                        coalesce((SELECT count(s.id) FROM schema_defs s WHERE s.current_host_id = h.id), 0)
                )
        """, [db_type_id], fn)
    }

    private def getHostConnection(connectionDetails, connectionName, fn) {
        JDBCClient
            .createShared(this.vertx, connectionDetails, connectionName)
            .getConnection({ hostConnectionHandler ->
                if (hostConnectionHandler.succeeded()) {
                    fn(hostConnectionHandler.result())
                } else {
                    throw "Unable to get connection: " +
                        hostConnectionHandler.cause().getMessage()
                }

            })
    }

    private def executeSerially(connection, statements, fn) {
        def executeHandler
        executeHandler = { statementQueue ->
            if (statementQueue.size() == 0) {
                fn()
            } else {
                def statement = statementQueue.get(0)
                statementQueue.remove(0)
                println "EXECUTING STATEMENT:" + statement
                connection.execute(statement, {
                    if (it.succeeded()) {
                        executeHandler(statementQueue)
                    } else {
                        println it.cause().getMessage()
                        throw it
                    }
                })
            }
        }
        executeHandler(statements)
    }

    private def executeScriptTemplate(hostConnection, script_template, batch_separator, databaseName, fn) {
        String delimiter = (char) 7
        String newline = (char) 10
        String carrageReturn = (char) 13

        // the scripts expect "databaseName" placeholders in the form of 2_abcde,
        def script = script_template.replaceAll('#databaseName#', databaseName)

        if (batch_separator && batch_separator.size()) {
            script = script.replaceAll(Pattern.compile(newline + batch_separator + carrageReturn + "?(" + newline + '|$)', Pattern.CASE_INSENSITIVE), delimiter)
        }
        this.executeSerially(hostConnection, script.tokenize(delimiter), fn)
    }

    private def buildRunningDatabase(dbDetails, short_code, ddl, statement_separator, fn) {
        // find a backend host capable of running our ddl...
        findAvailableHost(dbDetails.db_type_id, { host ->

            // get a connection to that host as an admin...
            this.getHostConnection([
                    url: host.jdbc_url_template.replace("#databaseName#", host.default_database),
                    driver_class: host.jdbc_class_name,
                    user: host.admin_username,
                    password: host.admin_password
                ],
                "admin_" + dbDetails.db_type_id, // connection pool name
                { adminHostConnection ->

                    String databaseName = "${dbDetails.db_type_id}_${short_code}".toString()
                    // use the admin host connection to setup a new, blank database in the host we have found...
                    this.executeScriptTemplate(adminHostConnection,
                        host.setup_script_template,
                        host.batch_separator,
                        databaseName,
                        {

                        // get a connection to the new, blank database as a non-admin user...
                        this.getHostConnection([
                                url: host.jdbc_url_template.replaceAll("#databaseName#", "db_" + databaseName),
                                driver_class: host.jdbc_class_name,
                                // assumes the setup script template builds the database with this pattern of credentials
                                user: "user_" + databaseName,
                                password: databaseName,
                                initial_pool_size: 1,
                                min_pool_size: 1,
                                max_pool_size: 2,
                                max_idle_time: 60
                            ],
                            "fiddle_" + databaseName, // connection pool name
                            { hostConnection ->
                                try {

                                    // timeout queries in case someone is trying to run something crazy
                                    // commented-out because it doesn't seem to work...?
                                    //hostConnection.setQueryTimeout((int)10)

                                    // consider refactoring below code to use executeScriptTemplate
                                    String delimiter = (char) 7
                                    String newline = (char) 10
                                    String carrageReturn = (char) 13

                                    // run the provided ddl to setup the database environment...
                                    if (host.batch_separator && host.batch_separator.size()) {
                                        ddl = ddl.replaceAll(Pattern.compile(newline + host.batch_separator + carrageReturn + "?(" + newline + '|$)', Pattern.CASE_INSENSITIVE), statement_separator)
                                    }

                                    // this monster regexp parses the query block by breaking it up into statements, each with three groups -
                                    // 1) Positive lookbehind - this group checks that the preceding characters are either the start or a previous separator
                                    // 2) The main statement body - this is the one we execute
                                    // 3) The end of the statement, as indicated by a terminator at the end of the line or the end of the whole DDL
                                    def statements = (Pattern.compile("(?<=(" + statement_separator + ")|^)([\\s\\S]*?)(?=(" + statement_separator + "\\s*\\n+)|(" + statement_separator + "\\s*\$)|\$)").matcher(ddl))
                                        .findAll({
                                            return (it[0].size() && ((Boolean) it[0] =~ /\S/) )
                                        })
                                        .collect({
                                            return it[0]
                                        })
                                    this.executeSerially(hostConnection, statements, {
                                        // statements must have executed successfully, close the various connections...
                                        hostConnection.close({
                                            adminHostConnection.close(fn)
                                        })
                                    });
                                } catch (e) {
                                    // something went wrong - probably bad ddl
                                    // close the non-admin host connection...
                                    hostConnection.close({
                                        // remove the database from the host...
                                        this.executeScriptTemplate(adminHostConnection,
                                            host.drop_script_template,
                                            host.batch_separator,
                                            databaseName,
                                            {
                                                adminHostConnection.close(fn)
                                                throw new Exception(e.getMessage())
                                            }
                                        )
                                    })
                                } // end try-catch
                            }) // end host connection
                        }) // end setup of host database
                    }) // end admin connection
                }) // end find available host

    } // end buildRunningDatabase


}