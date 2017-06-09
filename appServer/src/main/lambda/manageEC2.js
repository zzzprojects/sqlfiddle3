var Q = require('q');

var typeDetails = {
    "oracle11g": {
        "ImageId": process.env.ORACLE11G_AMI,
        "port": 1521
    },
    "sqlserver2014": {
        "ImageId": process.env.SQLSERVER2014_AMI,
        "port": 1433
    }
}

exports.runInstanceType = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ec2 = new AWS.EC2({"apiVersion": '2016-11-15'}),
        typeDetail = typeDetails[event.type];

    if (!typeDetail) {
        return callback(`Unrecogized type: ${event.type}`);
    }

    ec2.runInstances({
        ImageId: typeDetail.ImageId,
        MinCount: 1,
        MaxCount: 1,
        InstanceType: "t2.small",
        SubnetId: process.env.SUBNET_ID
    }, callback);
};

exports.terminateInstance = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ec2 = new AWS.EC2({"apiVersion": '2016-11-15'});

    ec2.terminateInstances({
        InstanceIds: [event.InstanceId]
    }, callback);
};

var getInstances = (params) => {
    var AWS = require('aws-sdk'),
        ec2 = new AWS.EC2({"apiVersion": '2016-11-15'});

    return ec2.describeInstances(params).promise()
    .then((response) =>
        response.Reservations
        .map((reservation) =>
            reservation.Instances
        )
        .reduce((acc, items) =>
            acc.concat(items),
            []
        )
    );
};

var findInstancesOfImage = (imageId) => {
    return getInstances({
        Filters: [{
            "Name": "image-id",
            "Values": [imageId]
        }, {
            "Name": "vpc-id",
            "Values": [process.env.VPC_ID]
        }]
    });
};

/*
event contains:
{ "type": "sqlserver2014" }
*/
exports.registerInstance = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        lambda = new AWS.Lambda({"apiVersion": '2015-03-31'}),
        typeDetail = typeDetails[event.type];

    if (!typeDetail) {
        return callback(`Unrecogized type: ${event.type}`);
    }

    return findInstancesOfImage(typeDetail.ImageId)
    .then((instances) =>
        lambda.invoke({
            FunctionName: "syncHosts",
            Payload: JSON.stringify({
                hostConnections: instances.map((instance) =>
                    ({
                        connection_meta: JSON.stringify({
                            type: "ec2",
                            InstanceId: instance.InstanceId
                        }),
                        port: typeDetail.port,
                        ip: instance.PrivateIpAddress
                    })
                ),
                hostType: typeDetail.type
            })
        }).promise()
    )
    .then((response) => callback(null, response))
    .catch((err) => callback(err));
};
