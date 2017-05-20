var Q = require('q');

const postgresConnectionConfig = {
    user: process.env.postgresUser,
    password: process.env.postgresPassword,
    database: 'sqlfiddle',
    host: process.env.postgresHost,
    port: 5432
};

// ipAddress, port and connection_meta are optional
var getHostTemplate = (hostType, ipAddress, port, connection_meta) => {
    var hostTemplates = {
        "mysql56Host": {
            "full_name": "MySQL 5.6",
            "jdbc_url_template": `jdbc:mysql://${ipAddress}:${port}/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8`,
            "default_database": "mysql",
            "admin_username": "root",
            "admin_password": "password",
            connection_meta
        },
        "postgresql93Host": {
            "full_name": "PostgreSQL 9.3",
            "jdbc_url_template": `jdbc:postgresql://${ipAddress}:${port}/#databaseName#`,
            "default_database": "postgres",
            "admin_username": "postgres",
            "admin_password": "password",
            connection_meta
        }
    };

    return hostTemplates[hostType];
};


var addHost = (client, host) => {
    return client.query({text: `
        INSERT INTO hosts (
            db_type_id,
            jdbc_url_template,
            default_database,
            admin_username,
            admin_password,
            connection_meta
        )
        SELECT
            id, $2, $3, $4, $5, $6
        FROM
            db_types
        WHERE full_name = $1
    `,
    values: [
        host.full_name,
        host.jdbc_url_template,
        host.default_database,
        host.admin_username,
        host.admin_password,
        host.connection_meta
    ]});
};

var deleteHost = (client, host) => {
    return client.query({text: `
        UPDATE
            schema_defs
        SET
            current_host_id = null
        WHERE
            current_host_id = ${host.id};

        DELETE FROM
            hosts
        WHERE
            id = ${host.id}
    `});
};

var scaleUpHost = (full_name) => {
    var AWS = require('aws-sdk'),
        lambda = new AWS.Lambda({"apiVersion": '2015-03-31'})
        nameToScaleFunction = {
        /*"Oracle 11g R2" : {
            "functionName": "",
            "arguments": ""
        },
        "MS SQL Server 2014" : {
            "functionName": "",
            "arguments": ""
        },
        "MS SQL Server 2008" : {
            "functionName": "",
            "arguments": ""
        },*/
        "MySQL 5.6" : {
            FunctionName: "addTask",
            Payload: JSON.stringify({
                serviceName: "ecscompose-service-mysql56"
            })
        },
        "PostgreSQL 9.3" : {
            FunctionName: "addTask",
            Payload: JSON.stringify({
                serviceName: "ecscompose-service-postgresql93"
            })
        }
    };

    AWS.config.setPromisesDependency(Q.Promise);

    return lambda.invoke(nameToScaleFunction[full_name]).promise();
};


var scaleDownHost = (host) => {
    var AWS = require('aws-sdk'),
        lambda = new AWS.Lambda({"apiVersion": '2015-03-31'}),
        meta = JSON.parse(host.connection_meta),
        typeFunctions = {
            "ecs" : "deleteTask"
        };

    AWS.config.setPromisesDependency(Q.Promise);

    return lambda.invoke({
        FunctionName: typeFunctions[meta.type],
        Payload: meta
    }).promise();
};



var deprovisionHostsPendingRemoval = (client) =>
    // get all hosts pending removal, so long as there are
    // other hosts of the same type which are not pending removal
    client.query(`
        SELECT
            h.*,
            d.full_name
        FROM
            hosts h
                INNER JOIN db_types d ON
                    h.db_type_id = d.id
        WHERE
            pending_removal = TRUE AND
            (
                SELECT
                    count(*)
                FROM
                    hosts h2
                WHERE
                    h2.db_type_id = h.db_type_id AND
                    pending_removal = FALSE
            ) > 0
    `).then((result) =>
        result.rows.map((host) =>
            deleteHost(client, host).then(() => scaleDownHost(host))
        )
    );

/**
  Expected to be called on via a scheduled CloudWatch task
*/

exports.checkForOverusedHosts = (event, context, callback) => {
    var pg = require('pg'),
        // variables provided from lambda environment
        client = new pg.Client(postgresConnectionConfig);

    client.connect(function (err) {
        client.query({ text: `
                SELECT
                    count(*) as number_schemas,
                    h.id as host_id,
                    d.full_name
                FROM
                    hosts h
                        INNER JOIN schema_defs s ON
                            h.id = s.current_host_id
                        INNER JOIN db_types d ON
                            h.db_type_id = d.id
                GROUP BY
                    h.id,
                    d.full_name
                HAVING
                    count(*) > $1
            `,
            values: [
                process.env.MAX_SCHEMAS_PER_HOST
            ]
        }).then((result) =>
            Q.all(
                result.rows.map((host) =>
                    client.query({
                        text: `
                            UPDATE
                                hosts
                            SET
                                pending_removal = TRUE
                            WHERE
                                id = $1
                        `,
                        values: [
                            host.host_id
                        ]
                    }).then(() =>
                        scaleUpHost(host.full_name)
                    )
                )
            )
            .then((results) => {
                client.end();
                callback(null, results);
            })
        );
    });
};


/**
  When this is called, "event" is expected to be a map like so:
  {
    "hostConnections": [
      {
        "connection_meta": "{\"type\":\"ecs\",\"taskArn\":\"arn:aws:ecs:u..\"}",
        "port": 32769,
        "ip": "10.0.1.49"
      }
    ],
    "hostType": "mysql56Host"
  }

*/
exports.syncHosts = (event, context, callback) => {
    var pg = require('pg'),
        client = new pg.Client(postgresConnectionConfig),
        baseHostTemplate = getHostTemplate(event.hostType);

    client.connect(function (err) {
        if (err) {
            callback(err);
            return;
        }

        client.query({ text: `
            SELECT
                h.*
            FROM
                hosts h
                    INNER JOIN db_types d ON
                        h.db_type_id = d.id
            WHERE
                full_name = $1
          `,
          values: [
              baseHostTemplate.full_name
          ]
        })
        .then((result) => {
            // a map with keys for each existing host jdbc url
            var registeredHosts = result.rows.reduce(
                    (result, host) => {
                        result[host.jdbc_url_template] = host;
                        return result;
                    }, {}
                ),
                desiredHosts = event.hostConnections.map(
                    (connection) => getHostTemplate(
                        event.hostType,
                        connection.ip,
                        connection.port,
                        connection.connection_meta
                    )
                ),
                promises = [];

            desiredHosts.forEach((host) => {
                if (!registeredHosts[host.jdbc_url_template]) {
                    // if we don't have a registration entry for this host, save it in the repo.
                    promises.push(addHost(client, host));
                } else {
                    // if we do have a registration entry, clear it.
                    delete registeredHosts[host.jdbc_url_template];
                }
            });

            // any remaining registeredHosts entries must be stale; remove them
            Object.keys(registeredHosts).forEach((key) => {
                var staleHost = registeredHosts[key];
                promises.push(deleteHost(client, staleHost));
            });

            return Q.all(promises);
        })
        .then((syncChanges) => {
            deprovisionHostsPendingRemoval(client);
            return syncChanges;
        })
        .then((syncChanges) => {
            client.end();
            callback(null, syncChanges);
        }, (err) => {
            client.end();
            callback(err);
        });
    });

};
