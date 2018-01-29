define(["Backbone"], function (Backbone) {
    return Backbone.Model.extend({
        defaults: {
            "sample_fragment":"",
            "notes":"",
            "simple_name": "",
            "full_name": "",
            "selected": false,
            "context": "host",
            "classname": "",
            "num_hosts": 0
        }
    });
});
