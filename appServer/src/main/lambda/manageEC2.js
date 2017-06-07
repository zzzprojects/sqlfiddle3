var Q = require('q');

var typeDetails = [
    {
        "ImageId": process.env.ORACLE11G_AMI,
        "port": 1521,
        "type": "oracle11g"
    },
    {
        "ImageId": process.env.SQLSERVER2014_AMI,
        "port": 1433,
        "type": "sqlserver2014"
    }
]

exports.runInstanceType = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        ec2 = new AWS.EC2({"apiVersion": '2016-11-15'}),
        typeDetail = typeDetails.filter((td) => td.type === event.type)[0];

    if (typeDetail) {
        ec2.runInstances({
            ImageId: typeDetail.ImageId,
            MinCount: 1,
            MaxCount: 1,
            InstanceType: "t2.small",
            SubnetId: process.env.SUBNET_ID
        }, callback);
    } else {
        callback(`Unable to find detail for type ${event.type}`);
    }
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

exports.registerInstance = (event, context, callback) => {
    var AWS = require('aws-sdk'),
        lambda = new AWS.Lambda({"apiVersion": '2015-03-31'});

    return getInstances({
        InstanceIds: [event.detail["instance-id"]]
    })
    .then((instances) => {
        if (!instances || instances.length !== 1) {
            throw `Unable to find the one instance passed to this function: ${event.detail["instance-id"]}`;
        }

        let ImageId = instances[0].ImageId;
        let typeDetail = typeDetails.filter((td) => td.ImageId === ImageId)[0];

        if (!typeDetail) {
            throw `Unrecogized ImageId: ${ImageId}`;
        }

        return typeDetail;
    })
    .then((typeDetail) =>
        findInstancesOfImage(typeDetail.ImageId)
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
    )
    .then((response) => callback(null, response))
    .catch((err) => callback(err));
};
