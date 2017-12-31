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
    const ext = new Api.Extensions(Api.config.getInCluster());

    const jsonStream = new JSONStream();
    var stream;

    var watchStream = (endpoint) => {
        console.log(new Date());
        console.log(JSON.stringify(endpoint, null, 4));

        var hostType = endpoint.object.metadata.name,
            runningSubsets = (endpoint.object.subsets || [])
                .filter((subset) => !!subset.addresses),
            notReadySubsets = (endpoint.object.subsets || [])
                .filter((subset) => !!subset.notReadyAddresses),
            hostTemplate = getHostTemplate(hostType),
            subsetsToHosts = (subsets, prop) =>
                subsets.length ? subsets[0][prop]
                    .map((hostAddress) => getHostTemplate(
                        hostType,
                        hostAddress.ip,
                        (subsets[0]
                                .ports
                                .filter((port) =>
                                    port.name === "database"
                                )[0] || {}).port,
                        hostAddress.targetRef.uid
                    )) : [];

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
                    desiredHosts = subsetsToHosts(runningSubsets, 'addresses'),
                    notReadyHosts = subsetsToHosts(notReadySubsets, 'notReadyAddresses');

                console.log("REGISTERED HOSTS:")
                console.log(JSON.stringify(registeredHosts, null, 4));
                console.log("DESIRED HOSTS:")
                console.log(JSON.stringify(desiredHosts, null, 4));
                console.log("NOT READY HOSTS:")
                console.log(JSON.stringify(notReadyHosts, null, 4));

                desiredHosts.forEach((host) => {
                    if (!registeredHosts[host.jdbc_url_template]) {
                        // if we don't have a registration entry for this host, save it in the repo.
                        addHost(client, host);
                    } else {
                        // if we do have a registration entry, clear it.
                        delete registeredHosts[host.jdbc_url_template];
                    }
                });

                notReadyHosts.forEach((host) => {
                    if (registeredHosts[host.jdbc_url_template]) {

                        if (registeredHosts[host.jdbc_url_template].pending_removal) {

                            // if we have a ready host, then we can safely scale down the replicas to remove this unready one
                            if (desiredHosts.length) {
                                deleteHost(client, registeredHosts[host.jdbc_url_template])
                                    .then(() => scale(ext, hostType, 1));
                            }

                        } else {

                            // if we a registration entry for this not ready host, mark it for removal and add another replica
                            markHostForRemoval(client, registeredHosts[host.jdbc_url_template]).then(
                                () => scale(ext, hostType, 2)
                            );

                        }

                        // since we do have a registration entry for this not ready host,
                        // clear it now so that it isn't removed below.
                        delete registeredHosts[host.jdbc_url_template];
                    }
                });

                // any remaining registeredHosts entries must be stale; remove them
                Object.keys(registeredHosts).forEach((key) => {
                    var staleHost = registeredHosts[key];
                    deleteHost(client, staleHost);
                });

            });
        }
    }

    // watch a stream of changes related to database hosts
    stream = core.ns.endpoints
        .matchLabels({ role: 'host' })
        .getStream({ qs: { watch: true } });
    stream.pipe(jsonStream);
    jsonStream.on('data', watchStream);

    // every 5 minutes, restart the watch....
    setInterval(() => {
        console.log('RESTARTING WATCH STREAM...');
        stream.abort();
        const jsonStream = new JSONStream();
        stream = core.ns.endpoints
            .matchLabels({ role: 'host' })
            .getStream({ qs: { watch: true } });
        stream.pipe(jsonStream);
        jsonStream.on('data', watchStream);
    }, 300000);

});


var scale = (ext, hostType, replicas) =>
    ext.ns.rs(hostType.replace('-service', '')).patch({
          body:  { spec: { replicas: replicas } }
        },
        (err, result) => console.log(JSON.stringify(err || result, null, 4))
    );


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

var markHostForRemoval = (client, host) =>
    client.query({text: `
        UPDATE
            hosts
        SET
            pending_removal = TRUE
        WHERE
            id = $1
    `,
    values: [
        host.id
    ]});

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
        DELETE FROM
            hosts
        WHERE
            id = $1
    `,
    values: [
        host.id
    ]});
};
