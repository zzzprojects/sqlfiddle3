const pg = require('pg');
const Q = require('q');

const postgresConnectionConfig = {
    user: "postgres",
    password: "password",
    database: "sqlfiddle",
    host: "appdatabase",
    port: 5432
};

const client = new pg.Client(postgresConnectionConfig);

client.connect(function (err) {
    if (err) {
        console.log('Failure to connect to appdatabase...');
        console.log(err);

        setTimeout(() => {
            process.exit(1);
        }, 2000);

        return;
    }
    const Api = require('kubernetes-client');
    const JSONStream = require('json-stream');

    const core = new Api.Core(Api.config.getInCluster());
    const jsonStream = new JSONStream();

    // watch a stream of changes related to database hosts
    const stream = core.ns.endpoints
        .matchLabels({ role: 'host' })
        .getStream({ qs: { watch: true } });

    stream.pipe(jsonStream);
    jsonStream.on('data', endpoint => {
        console.log(JSON.stringify(endpoint, null, 4));

        var hostType = endpoint.object.metadata.name,
            runningSubsets = (endpoint.object.subsets || [])
                .filter((subset) => !!subset.addresses),
            runningHosts = [],
            hostTemplate = getHostTemplate(hostType);

        if (runningSubsets.length) {
            runningHosts = runningSubsets[0]
                .addresses
                .map((hostAddress) => ({
                    ip: hostAddress.ip,
                    port: (runningSubsets[0]
                            .ports
                            .filter((port) =>
                                port.name === "database"
                            )[0] || {}).port,
                    connection_meta:  hostAddress.targetRef.uid
                })
            );
        }

        if (hostTemplate) {
            getCurrentHostsByFullName(client, hostTemplate.full_name)
            .then((current_hosts) => {
                // a map with keys for each existing host jdbc url
                var registeredHosts = current_hosts.rows.reduce(
                        (result, host) => {
                            result[host.jdbc_url_template] = host;
                            return result;
                        }, {}
                    ),
                    desiredHosts = runningHosts.map(
                        (runningHost) => getHostTemplate(
                            hostType,
                            runningHost.ip,
                            runningHost.port,
                            runningHost.connection_meta
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
            });
        }
    });

    setTimeout(() => {
        console.log('ENDING WATCH STREAM...');
        stream.abort();
        process.exit(0);
    }, 1500000);

});

var getCurrentHostsByFullName = (client, full_name) =>
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
          full_name
      ]
    });

// ipAddress, port and connection_meta are optional
var getHostTemplate = (hostType, ipAddress, port, connection_meta) => {
    var hostTemplates = {
        "mysql56-service": {
            "full_name": "MySQL 5.6",
            "jdbc_url_template": `jdbc:mysql://${ipAddress}:${port}/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8`,
            "default_database": "mysql",
            "admin_username": "root",
            "admin_password": "password",
            connection_meta
        },
        "postgresql93-service": {
            "full_name": "PostgreSQL 9.3",
            "jdbc_url_template": `jdbc:postgresql://${ipAddress}:${port}/#databaseName#`,
            "default_database": "postgres",
            "admin_username": "postgres",
            "admin_password": "password",
            connection_meta
        },
        "postgresql96-service": {
            "full_name": "PostgreSQL 9.6",
            "jdbc_url_template": `jdbc:postgresql://${ipAddress}:${port}/#databaseName#`,
            "default_database": "postgres",
            "admin_username": "postgres",
            "admin_password": "password",
            connection_meta
        },
        "mssql2017-service": {
            "full_name": "MS SQL Server 2017",
            "jdbc_url_template": `jdbc:jtds:sqlserver://${ipAddress}:${port}/#databaseName#`,
            "default_database": "master",
            "admin_username": "sa",
            "admin_password": "SQLServerPassword!",
            connection_meta
        },
        "oracle11g-service": {
            "full_name": "Oracle 11g R2",
            "jdbc_url_template": `jdbc:oracle:thin:@//${ipAddress}:${port}/xe`,
            "default_database": "XE",
            "admin_username": "system",
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
