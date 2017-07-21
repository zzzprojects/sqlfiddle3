var Q = require('q');

/*
  Deletes the oldest task associated with a given task definition,
  as long as there is a younger task still available.
*/
exports.killTask = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ecs = new AWS.ECS({"apiVersion": '2014-11-13'}),
        cluster = process.env.CLUSTERNAME,
        taskDefinitionArn = event,
        serviceName = taskDefinitionArn.split('/').slice(-1)[0].split(":")[0].replace('-', '-service-')

    ecs.listTasks({ cluster, serviceName }).promise()
    .then((taskList) => ecs.describeTasks({ cluster, tasks: taskList.taskArns }).promise())
    .then((taskDetails) => {
        let sortedByOldest = taskDetails.tasks.sort((a,b) =>
            (a.startedAt < b.startedAt) ? -1 : 1
        );
        if (sortedByOldest.length > 1) {
            return ecs.stopTask({ cluster, task: sortedByOldest[0].taskArn }).promise()
                .then(() => `Stopped ${sortedByOldest[0].taskArn}`);
        } else {
            return "Unable to stop task, not enough available"
        }
    })
    .then((result) => callback(null, result));
};
