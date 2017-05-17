
const postgresConnectionConfig = {
    user: process.env.postgresUser,
    password: process.env.postgresPassword,
    database: 'sqlfiddle',
    host: process.env.postgresHost,
    port: 5432
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
 * This lambda function is expected to be called from API Gateway
 * event is expected to have this structure:
  {
    "queryStringParameters": {
        "containerType": "mysql56",
        "ipAddress": "10.0.0.20"
    }
  }
 */
exports.addHost = (event, context, callback) => {
    var pg = require('pg'),
        // variables provided from lambda environment
        client = new pg.Client(postgresConnectionConfig);

    client.on('drain', client.end.bind(client));
    var hostTemplates = {
        "mysql56": {
            "full_name": "MySQL 5.6",
            "jdbc_url_template": "jdbc:mysql://#ipAddress#:3306/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8",
            "default_database": "mysql",
            "admin_username": "root",
            "admin_password": "password"
        },
        "postgresql93": {
            "full_name": "PostgreSQL 9.3",
            "jdbc_url_template": "jdbc:postgresql://#ipAddress#:5432/#databaseName#",
            "default_database": "postgres",
            "admin_username": "postgres",
            "admin_password": "password"
        }
    },
    {containerType, ipAddress} = event.queryStringParameters || {};

    client.connect(function (err) {
        var query = client.query({
          text: "INSERT INTO hosts (db_type_id, jdbc_url_template, default_database, admin_username, admin_password)"+
                "SELECT id, $2, $3, $4, $5 FROM db_types WHERE full_name = $1",
          values: [
              hostTemplates[containerType].full_name,
              hostTemplates[containerType].jdbc_url_template.replace("#ipAddress#", ipAddress),
              hostTemplates[containerType].default_database,
              hostTemplates[containerType].admin_username,
              hostTemplates[containerType].admin_password
          ]
        }, function(err) {
            if (!err) {
                callback(null, {
                    "statusCode": 200,
                    "headers": {},
                    "body": 'Successfully registered host'
                });
            } else {
                callback(null, {
                    "statusCode": 400,
                    "headers": {},
                    "body": JSON.stringify(err)
                });
            }
        });
    });
};
