var Q = require('q');

const postgresConnectionConfig = {
    user: process.env.postgresUser,
    password: process.env.postgresPassword,
    database: 'sqlfiddle',
    host: process.env.postgresHost,
    port: 5432
};

// ipAddress and port are optional; if not provided, the jdbc_url_template will be unusable
var getHostTemplate = (hostType, ipAddress, port) => {
    var hostTemplates = {
        "mysql56Host": {
            "full_name": "MySQL 5.6",
            "jdbc_url_template": `jdbc:mysql://${ipAddress}:${port}/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8`,
            "default_database": "mysql",
            "admin_username": "root",
            "admin_password": "password"
        },
        "postgresql93Host": {
            "full_name": "PostgreSQL 9.3",
            "jdbc_url_template": `jdbc:postgresql://${ipAddress}:${port}/#databaseName#`,
            "default_database": "postgres",
            "admin_username": "postgres",
            "admin_password": "password"
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
            admin_password
        )
        SELECT
            id, $2, $3, $4, $5
        FROM
            db_types
        WHERE full_name = $1
    `,
    values: [
        host.full_name,
        host.jdbc_url_template,
        host.default_database,
        host.admin_username,
        host.admin_password
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


exports.testConnection = (event, context, callback) => {
    var pg = require('pg'),
        // variables provided from lambda environment
        client = new pg.Client(postgresConnectionConfig);

    client.on('drain', client.end.bind(client));
    client.connect(function (err) {
        var query = client.query("SELECT count(*) as n FROM hosts", function(err, result) {
            callback(null, 'Found this many hosts: ' + result.rows[0].n);
        });
    });
};


/**
  When this is called, "event" is expected to be a map like so:
  {
    "hostConnections": [
      {
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
                        connection.port
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
            client.end();
            callback(null, syncChanges);
        }, (err) => {
            client.end();
            callback(err);
        });
    });

};
