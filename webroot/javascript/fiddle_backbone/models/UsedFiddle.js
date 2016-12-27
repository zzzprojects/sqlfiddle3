define(["Backbone"], function (Backbone) {

    var UsedFiddle = Backbone.Model.extend({
        defaults: {
            "fragment": "",
            "favorite": false,
            "num_accesses": 0,
            "full_name": "",
            "ddl": "",
            "sql": "",
            "structure": [],
            "sets": []
        },
        initialize: function () {
            if (!this.get("last_used")) {
                this.set("last_used", new Date());
            }
        }
    });

    return UsedFiddle;

});
