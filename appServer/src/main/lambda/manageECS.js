exports.addTask = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ecs = new AWS.ECS({"apiVersion": '2014-11-13'}),
        cluster = process.env.CLUSTERNAME,
        serviceName = process.env.SERVICE;

    ecs.listTasks({ cluster, serviceName }, (err, data) => {
        ecs.updateService({
            desiredCount: data.taskArns.length+1,
            service: serviceName,
            cluster
        }, callback);
    });
};
