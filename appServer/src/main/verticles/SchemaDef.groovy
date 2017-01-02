import java.security.MessageDigest
import io.vertx.core.json.JsonObject

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

        def schemaQuery
        if (content.short_code) {
            schemaQuery = [
                sql: this.getSQL("WHERE s.short_code = ? AND s.md5 = ? AND s.db_type_id = ?"),
                params: [
                    content.short_code,
                    md5hash,
                    content.db_type_id
                ]
            ]
        } else {
            schemaQuery = [
                sql: this.getSQL("WHERE s.md5 = ? AND s.db_type_id = ?"),
                params: [
                    md5hash,
                    content.db_type_id
                ]
            ]
        }
        DatabaseClient.singleRead(this.vertx,
            schemaQuery.sql,
            schemaQuery.params,
            { existing_schema ->
                if (existing_schema != null) {
                    fn([
                        _id: "${content.db_type_id}_${existing_schema.short_code}".toString(),
                        short_code: existing_schema.short_code,
                        schema_structure: existing_schema.structure_json != null ?
                            new JsonObject(existing_schema.structure_json) : null
                    ])
                } else {
                    this.attemptToBuildSchema(content, md5hash, fn)
                }
            }
        )
    }

    static private String getSQL(where) {
        return """
        SELECT
            s.id,
            s.md5,
            s.db_type_id,
            s.short_code,
            to_char(s.last_used, 'YYYY-MM-DD HH24:MI:SS.MS') as last_used,
            floor(EXTRACT(EPOCH FROM age(current_timestamp, last_used))/60) as minutes_since_last_used,
            coalesce(s.ddl, '') as ddl,
            s.statement_separator,
            s.structure_json,
            s.deprovision,
            d.simple_name,
            d.full_name,
            d.context,
            d.batch_separator,
            coalesce(hosts_available.total, 0) as num_hosts_available
        FROM
            schema_defs s
                INNER JOIN db_types d ON
                    s.db_type_id = d.id
                LEFT OUTER JOIN (
                    SELECT h.db_type_id, count(*) as total
                    FROM hosts h
                    GROUP BY h.db_type_id
                ) as hosts_available ON
                    d.id = hosts_available.db_type_id
        ${where}
        """
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

    private def attemptToBuildSchema(content, md5hash, fn) {

//        def db_type = DBTypes.getDBType(this.vertx, content.db_type_id)
/*
        if (db_type.context == "host" && db_type.num_hosts == 0) {
            throw new NoHostException("No host of this type available to create schema. Try using a different database version.")
        }
*/
//        def structure = []

        this.getUniqueShortCode(content.db_type_id, md5hash, { short_code ->
            this.create([
                "db_type_id": content.db_type_id,
                "short_code": short_code,
                "md5": md5hash,
                "ddl": content.ddl,
                "statement_separator": content.statement_separator
                //"structure": structure
            ], { result ->
                fn([
                    _id: "${content.db_type_id}_${short_code}".toString(),
                    short_code: short_code
                    //schema_structure: existing_schema.structure_json != null ?
                    //    new JsonObject(existing_schema.structure_json) : null
                ])
            })
        })

/*

        // we only need to attempt to create a DB if the context for it is "host"
        if (db_type.context == "host") {

            // if there is an error thrown from here, it will be caught below;
            // It is necessary to build the real db at this stage so that we can fail early if there
            // is a problem (and get a handle on the real error involved in the creation)
            def hostDetails = openidm.create("system/hosts/databases", null, [
                "db_type_id": content.db_type_id,
                "schema_name": "db_" + content.db_type_id + "_" + short_code,
                "username": "user_" + content.db_type_id + "_" + short_code,
                "pw": content.db_type_id + "_" + short_code,
                "ddl": content.ddl ?: "",
                "statement_separator": content.statement_separator
            ])

            Map schema_filters = [
                "SQL Server": "dbo",
                "MySQL": null,
                "PostgreSQL": "public",
                "Oracle": ("user_" + content.db_type_id + "_" + short_code).toUpperCase()
            ]

            if (schema_filters.containsKey(db_type.get('simple_name'))) {

                Sql hostConnection = Sql.newInstance(hostDetails.get('jdbc_url'), hostDetails.get('username'), hostDetails.get('pw'), hostDetails.get('jdbc_class_name'))
                hostConnection.withStatement { ((Statement) it).setQueryTimeout(10) }

                structure = getSchemaStructure(hostConnection, db_type, schema_filters[db_type.get('simple_name')])

                hostConnection.close()

            }

        }

        // this schema_def will be linked to the above running db below as part of reconById
        schema_def = openidm.create("system/fiddles/schema_defs", null, [
            "db_type_id": content.db_type_id,
            "short_code": short_code,
            "md5": md5hash,
            "ddl": content.ddl,
            "statement_separator": content.statement_separator,
            "structure": structure
        ])

        */
    }

}
