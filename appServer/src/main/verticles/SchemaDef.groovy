import io.vertx.core.json.JsonObject

class SchemaDef {
    private vertx
    private Integer schema_def_id
    private Integer db_type_id
    private String short_code
    private String md5
    private String ddl
    private String statement_separator
    private String batch_separator
    private String simple_name
    private String full_name
    private String context
    private String execution_plan_prefix
    private String execution_plan_suffix
    private Integer current_host_id

    SchemaDef(vertx) {
        this.vertx = vertx
    }

    SchemaDef(vertx, db_type_id, short_code) {
        this.vertx = vertx
        this.db_type_id = db_type_id
        this.short_code = short_code
    }

    def getBasicDetails(fn) {
        def returnDetails = { result ->
            if (result) {
                fn([
                    "short_code": this.short_code,
                    "ddl": this.ddl,
                    "schema_statement_separator": this.statement_separator,
                    "schema_structure": null,
                    "full_name": this.full_name
                ])
            } else {
                fn(null)
            }
        }
        if (this.schema_def_id) {
            returnDetails(true)
        } else {
            this.readFromDatabase(returnDetails)
        }
    }

    Integer getId() {
        return schema_def_id
    }

    String getContext() {
        return context
    }

    String getShortCode() {
        return short_code
    }

    Integer getCurrentHostId() {
        return current_host_id
    }

    String getBatchSeparator() {
        return batch_separator
    }

    String getExecutionPlanPrefix() {
        return execution_plan_prefix?:""
    }

    String getExecutionPlanSuffix() {
        return execution_plan_suffix?:""
    }

    private readFromDatabase(fn) {
        DatabaseClient.singleRead(this.vertx, """
            SELECT
                s.id as schema_def_id,
                s.ddl,
                s.md5,
                s.statement_separator,
                s.current_host_id,
                d.simple_name,
                d.full_name,
                d.context,
                d.batch_separator,
                d.execution_plan_prefix,
                d.execution_plan_suffix
            FROM
                db_types d
                    INNER JOIN schema_defs s ON
                        d.id = s.db_type_id AND
                        s.short_code = ?
            WHERE
                d.id = ?
            """,
                [ this.short_code, this.db_type_id ],
            { schema_def ->
                if (schema_def != null) {
                    this.schema_def_id = schema_def.schema_def_id
                    this.ddl = schema_def.ddl
                    this.md5 = schema_def.md5
                    this.statement_separator = schema_def.statement_separator
                    this.current_host_id = schema_def.current_host_id
                    this.simple_name = schema_def.simple_name
                    this.full_name = schema_def.full_name
                    this.context = schema_def.context
                    this.batch_separator = schema_def.batch_separator
                    this.execution_plan_prefix = schema_def.execution_plan_prefix
                    this.execution_plan_suffix = schema_def.execution_plan_suffix
                    fn(true)
                } else {
                    fn(false)
                }
            }
        )
    }

    def processCreateRequest(content, fn) {
        assert content.db_type_id && content.db_type_id instanceof Integer
        assert content.ddl.size() <= 8000

        this.db_type_id = content.db_type_id
        this.ddl = content.ddl

        this.md5 = RESTUtils.getMD5((String) content.statement_separator + content.ddl)

        if (!content.statement_separator) {
            this.statement_separator = ";"
        } else {
            this.statement_separator = content.statement_separator
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
            [ this.md5, this.db_type_id ],
            { dbDetails ->
                if (dbDetails == null) {
                    fn([
                        "error": "Unable to find database type"
                    ])
                } else {
                    if (dbDetails.short_code != null) {
                        this.short_code = dbDetails.short_code
                        fn([
                            _id: this.getDatabaseName(),
                            short_code: this.short_code,
                            schema_structure: null //dbDetails.structure_json != null ?
                                //new JsonObject(dbDetails.structure_json) : null
                        ])
                    } else {
                        this.context = dbDetails.context
                        this.registerSchema(fn)
                    }
                }
            }
        )
    }

    private getUniqueShortCode(fn) {
        def short_code = this.md5.substring(0,5)

        DatabaseClient.getConnection(this.vertx, {connection ->
            connection.queryWithParams("""
            SELECT
                short_code
            FROM
                schema_defs s
            WHERE
                s.db_type_id = ? AND
                s.short_code LIKE ?
            """, [this.db_type_id, this.short_code + "%"], { possibleConflicts ->
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
                        short_code = this.md5.substring(0,short_code.size()+1)
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

    private saveToDatabase(fn) {
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
            VALUES (?,?,?,?,?,?,?,current_timestamp)
            """, [
                this.db_type_id,
                this.short_code,
                this.ddl,
                this.md5,
                this.statement_separator,
                this.current_host_id,
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

    private registerSchema(fn) {

        this.getUniqueShortCode({ short_code ->
            this.short_code = short_code
            // if the dbType context is "host", then we have to try to create the database in our
            // backend environment before we try to save the schema definition
            if (this.context == "host") {
                this.buildRunningDatabase(
                { host, hostConnection ->
                    hostConnection.close()
                    this.current_host_id = host.host_id
                    this.saveToDatabase({ result ->
                        fn([
                            _id: this.getDatabaseName(),
                            short_code: this.short_code
                        ])
                    })
                },
                {
                    fn([
                        "error": it
                    ])
                })
            } else { // context is not in our backend, so don't need to attempt to build it first
                this.saveToDatabase({ result ->
                    fn([
                        _id: this.getDatabaseName(),
                        short_code: this.short_code
                    ])
                })
            }
        })
    }

    private executeScriptTemplate(hostConnection, script_template, batch_separator, successHandler, errorHandler) {
        String delimiter = (char) 7

        // the scripts expect "databaseName" placeholders in the form of 2_abcde,
        def script = script_template.replaceAll('#databaseName#', this.getDatabaseName())

        def statements = DatabaseClient.parseStatementGroups(script, delimiter, batch_separator)

        DatabaseClient.executeSerially(hostConnection, statements, successHandler, errorHandler)
    }

    String getDatabaseName() {
        return "${this.db_type_id}_${this.short_code}".toString()
    }

    def buildRunningDatabase(successHandler, errorHandler) {
        // find a backend host capable of running our ddl...
        DBTypes.findAvailableHost(this.vertx, this.db_type_id, { host ->

            // get a connection to that host as an admin...
            host.getAdminHostConnection(this.vertx,
                { adminHostConnection ->

                    // use the admin host connection to setup a new, blank database in the host we have found...
                    this.executeScriptTemplate(adminHostConnection,
                        host.setup_script_template,
                        host.batch_separator,
                        // execute the user's ddl within this new host...
                        {
                            this.executeDDL(adminHostConnection, host, successHandler, errorHandler)
                        },
                        // deal with a failure to create the host...
                        {
                            // if we have trouble setting up a new database, it's likely due to a conflict with an existing one
                            // therefore, try to delete it.
                            this.dropDatabase(host, adminHostConnection, {
                                // try again after having dropped the database
                                this.executeScriptTemplate(adminHostConnection,
                                    host.setup_script_template,
                                    host.batch_separator,
                                    {
                                        this.executeDDL(adminHostConnection, host, successHandler, errorHandler)
                                    },
                                    { errorMessage ->
                                        // give up if we are still unable to build the database
                                        this.dropDatabase(host, adminHostConnection, {
                                            errorHandler(errorMessage)
                                        })
                                    }
                                )

                            })

                        }
                    ) // end setup of host database
                    }, errorHandler) // end admin connection
                }, {
                    errorHandler("No host of this type available to create schema. Try using a different database version.")
                }
        ) // end find available host

    } // end buildRunningDatabase

    def executeDDL (adminHostConnection, host, successHandler, errorHandler) {
        // get a connection to the new, blank database as a non-admin user...
        host.getUserHostConnection(this.vertx, this.getDatabaseName(), { hostConnection ->
            // timeout queries in case someone is trying to run something crazy
            // commented-out because it doesn't seem to work...?
            //hostConnection.setQueryTimeout((int)10)

            def statements = DatabaseClient.parseStatementGroups(this.ddl, this.statement_separator, host.batch_separator)

            DatabaseClient.executeSerially(hostConnection, statements, {
                adminHostConnection.close({
                    successHandler(host, hostConnection)
                })
            },
            { errorMessage ->
                // something went wrong - probably bad ddl
                // close the non-admin host connection...
                hostConnection.close({
                    this.dropDatabase(host, adminHostConnection, errorHandler)
                })
            })
        }, errorHandler) // end host connection
    }

    def dropDatabase(host, hostConnection, handler) {
        // remove the database from the host...
        this.executeScriptTemplate(hostConnection,
            host.drop_script_template,
            host.batch_separator,
            handler,
            handler
        )
    }


    def updateCurrentHost(current_host_id, fn) {
        DatabaseClient.getConnection(this.vertx, {connection ->
            connection.updateWithParams("""
            UPDATE
                schema_defs
            SET
                current_host_id = ?
            WHERE
                id = ?
            """,
            [ current_host_id, this.schema_def_id ], {
                connection.close()
                if (it.succeeded()) {
                    this.current_host_id = current_host_id
                    fn(it.result())
                } else {
                    throw new Exception(it.cause().getMessage())
                }
            })
        })
    }
}
