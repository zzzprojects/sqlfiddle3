import io.vertx.groovy.ext.jdbc.JDBCClient

class Host {
    Integer host_id
    String jdbc_url_template
    String jdbc_class_name
    String default_database
    String admin_username
    String admin_password
    String setup_script_template
    String drop_script_template
    String batch_separator

    Host(Integer host_id) {
        this.host_id = host_id
    }
    Host(Map hostDetails) {
        this.saveDetails(hostDetails)
    }

    private readHostDetails(vertx, fn) {
        DatabaseClient.singleRead(vertx, """
            SELECT
                h.id as host_id,
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
                h.id = ?
        """, [this.host_id], { result ->
            if (result != null) {
                this.saveDetails(result)
                fn()
            } else {
                throw new Exception("Unable to find host for provided id")
            }
        })
    }

    private saveDetails(Map hostDetails) {
        this.host_id = hostDetails.host_id
        this.jdbc_class_name = hostDetails.jdbc_class_name
        this.jdbc_url_template = hostDetails.jdbc_url_template
        this.default_database = hostDetails.default_database
        this.admin_username = hostDetails.admin_username
        this.admin_password = hostDetails.admin_password
        this.setup_script_template = hostDetails.setup_script_template
        this.drop_script_template = hostDetails.drop_script_template
        this.batch_separator = hostDetails.batch_separator
    }

    private getHostConnection(vertx, connectionDetails, connectionName, fn) {
        JDBCClient
                .createShared(vertx, connectionDetails, connectionName)
                .getConnection({ hostConnectionHandler ->
            if (hostConnectionHandler.succeeded()) {
                fn(hostConnectionHandler.result())
            } else {
                throw new Exception("Unable to get connection: " +
                        hostConnectionHandler.cause().getMessage())
            }

        })
    }

    def getAdminHostConnection(vertx, fn) {
        def readyFunction = {
            this.getHostConnection(vertx,
                [
                    url: this.jdbc_url_template.replace("#databaseName#", this.default_database),
                    driver_class: this.jdbc_class_name,
                    user: this.admin_username,
                    password: this.admin_password
                ],
                "admin_" + this.host_id,
                fn
            )
        }
        if (!this.jdbc_url_template) {
            this.readHostDetails(vertx, readyFunction)
        } else {
            readyFunction()
        }
    }

    def getUserHostConnection(vertx, databaseName, fn) {
        def readyFunction = {
            this.getHostConnection(vertx,
                [
                    url: this.jdbc_url_template.replaceAll("#databaseName#", "db_" + databaseName),
                    driver_class: this.jdbc_class_name,
                    // assumes the setup script template builds the database with this pattern of credentials
                    user: "user_" + databaseName,
                    password: databaseName,
                    initial_pool_size: 1,
                    min_pool_size: 1,
                    max_pool_size: 1,
                    max_idle_time: 1
                ],
                "fiddle_" + databaseName,
                fn
            )
        }
        if (!this.jdbc_url_template) {
            this.readHostDetails(vertx, readyFunction)
        } else {
            readyFunction()
        }
    }

}
