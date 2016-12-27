define(["./OpenIDMResource", "Backbone", "./UsedFiddle"], function (idm, Backbone, UsedFiddle) {
    return Backbone.Collection.extend({
        fetch: function () {
            var _this = this;
            return idm.serviceCall({
                url: "/favorites?_queryId=myFavorites"
            })
            .then(function (data) {
                _this.reset(_.map(data.result, function (r) {
                    return new UsedFiddle({
                        "id": r._id,
                        "fragment": "!" + r.db_type_id + "/" + r.short_code + (r.query_id !== null ? ("/" + r.query_id) : ""),
                        "favorite": r.favorite,
                        "num_accesses": r.num_accesses,
                        "last_used": r.last_accessed,
                        "full_name": r.full_name,
                        "ddl": r.ddl,
                        "sql": r.sql,
                        "structure": r.structure,
                        "sets": r.sets
                    });
                }));
                return _this;
            });
        }
    });
});
