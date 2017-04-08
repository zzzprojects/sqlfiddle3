exports.testConnection = (event, context, callback) => {

    var pg = require('pg');

    // variables provided from lambda environment
    var client = new pg.Client({
        user: postgresUser,
        password: postgresPassword,
        database: 'sqlfiddle',
        host: postgresHost,
        port: 5432
    });

    client.on('drain', client.end.bind(client));

    // connect to our database
    client.connect(function (err) {
        var query = client.query("SELECT count(*) as n FROM hosts", function(err, result) {
            console.log(result.rows[0].n);

            callback(null, 'Hello from Lambda: ' + result.rows[0].n);
        });
    });
};