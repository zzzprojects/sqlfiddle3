import io.vertx.core.json.JsonObject
import java.util.regex.Pattern

class SchemaDef {
    private vertx
    private Integer db_type_id
    private String short_code

    SchemaDef(vertx) {
        this.vertx = vertx
    }

    SchemaDef(vertx, db_type_id, short_code) {
        this.vertx = vertx
        this.db_type_id = db_type_id
        this.short_code = short_code
    }

    def processCreateRequest(content, fn) {
        assert content.db_type_id && content.db_type_id instanceof Integer
        assert content.ddl.size() <= 8000
        this.db_type_id = content.db_type_id

        def md5hash = RESTUtils.getMD5((String) content.statement_separator + content.ddl)

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
                    fn([
                        "error": "Unable to find database type"
                    ])
                } else {
                    if (dbDetails.short_code != null) {
                        this.short_code = dbDetails.short_code
                        // schema_def already registered, return it
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
            }
        )
    }

    private getUniqueShortCode(db_type_id, md5hash, fn) {
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

    private create(createAttributes, fn) {
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
                current_host_id,
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
                createAttributes.current_host_id,
                null
                //structure != null ? (new JsonBuilder(structure).toString()) : null
            ], {
                connection.close()
                if (it.succeeded()) {
                    fn(it.result())
                } else {
                    throw new Exception(it.cause().getMessage())
                }
            })
        })
    }

    private registerSchema(content, md5hash, dbDetails, fn) {

        this.getUniqueShortCode(content.db_type_id, md5hash, { short_code ->
            this.short_code = short_code
            // if the dbType context is "host", then we have to try to create the database in our
            // backend environment before we try to save the schema definition
            if (dbDetails.context == "host") {
                this.buildRunningDatabase(
                content.ddl,
                content.statement_separator,
                { current_host_id, hostConnection ->
                    hostConnection.close()
                    this.create([
                        "db_type_id": content.db_type_id,
                        "short_code": short_code,
                        "md5": md5hash,
                        "ddl": content.ddl,
                        "statement_separator": content.statement_separator,
                        "current_host_id": current_host_id,
                        "structure": null
                    ], { result ->
                        fn([
                            _id: "${content.db_type_id}_${short_code}".toString(),
                            short_code: short_code
                        ])
                    })
                },
                {
                    fn([
                        "error": it
                    ])
                })
            } else { // context is not in our backend, so don't need to attempt to build it first
                this.create([
                    "db_type_id": content.db_type_id,
                    "short_code": short_code,
                    "md5": md5hash,
                    "ddl": content.ddl,
                    "statement_separator": content.statement_separator,
                    "current_host_id": null,
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

    private executeSerially(connection, statements, successHandler, errorHandler) {
        def executeHandler
        executeHandler = { statementQueue ->
            if (statementQueue.size() == 0) {
                successHandler()
            } else {
                def statement = statementQueue.get(0)
                statementQueue.remove(0)
                connection.execute(statement, {
                    if (it.succeeded()) {
                        executeHandler(statementQueue)
                    } else {
                        errorHandler(it.throwable.getMessage())
                    }
                })
            }
        }
        executeHandler(statements)
    }

    private executeScriptTemplate(hostConnection, script_template, batch_separator, databaseName, successHandler, errorHandler) {
        String delimiter = (char) 7
        String newline = (char) 10
        String carrageReturn = (char) 13

        // the scripts expect "databaseName" placeholders in the form of 2_abcde,
        def script = script_template.replaceAll('#databaseName#', databaseName)

        if (batch_separator && batch_separator.size()) {
            script = script.replaceAll(Pattern.compile(newline + batch_separator + carrageReturn + "?(" + newline + '|$)', Pattern.CASE_INSENSITIVE), delimiter)
        }
        this.executeSerially(hostConnection, script.tokenize(delimiter), successHandler, errorHandler)
    }

    String getDatabaseName() {
        return "${this.db_type_id}_${this.short_code}".toString()
    }

    def buildRunningDatabase(ddl, statement_separator, successHandler, errorHandler) {
        // find a backend host capable of running our ddl...
        DBTypes.findAvailableHost(this.vertx, this.db_type_id, { host ->

            // get a connection to that host as an admin...
            host.getAdminHostConnection(this.vertx,
                { adminHostConnection ->

                    String databaseName = this.getDatabaseName()
                    // use the admin host connection to setup a new, blank database in the host we have found...
                    this.executeScriptTemplate(adminHostConnection,
                        host.setup_script_template,
                        host.batch_separator,
                        databaseName,
                        {

                        // get a connection to the new, blank database as a non-admin user...
                        host.getUserHostConnection(this.vertx, databaseName,
                            { hostConnection ->
                                // timeout queries in case someone is trying to run something crazy
                                // commented-out because it doesn't seem to work...?
                                //hostConnection.setQueryTimeout((int)10)

                                // consider refactoring below code to use executeScriptTemplate
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
                                    adminHostConnection.close({
                                        successHandler(host.host_id, hostConnection)
                                    })
                                },
                                { errorMessage ->
                                    // something went wrong - probably bad ddl
                                    // close the non-admin host connection...
                                    hostConnection.close({
                                        // remove the database from the host...
                                        this.executeScriptTemplate(adminHostConnection,
                                            host.drop_script_template,
                                            host.batch_separator,
                                            databaseName,
                                            {
                                                adminHostConnection.close({
                                                    errorHandler(errorMessage)
                                                })
                                            },
                                            {
                                                // somehow failed to drop the database?
                                                errorHandler(errorMessage)
                                            }
                                        )
                                    })

                                })
                            }) // end host connection
                        }, {
                            // failed somehow to create host database....
                            errorHandler(it)
                        }) // end setup of host database
                    }) // end admin connection
                }, {
                    errorHandler("No host of this type available to create schema. Try using a different database version.")
                }
        ) // end find available host

    } // end buildRunningDatabase


    def updateCurrentHost(schema_def_id, current_host_id, fn) {
        DatabaseClient.getConnection(this.vertx, {connection ->
            connection.updateWithParams("""
            UPDATE
                schema_defs
            SET
                current_host_id = ?
            WHERE
                id = ?
            """, [
                current_host_id, schema_def_id
            ], {
                connection.close()
                if (it.succeeded()) {
                    fn(it.result())
                } else {
                    throw new Exception(it.cause().getMessage())
                }
            })
        })
    }
}
