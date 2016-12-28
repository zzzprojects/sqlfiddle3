define(["./OpenIDMResource", "Backbone", "./DBType"], function (idm, Backbone, DBType) {

    return Backbone.Collection.extend({
        model: DBType,
        fetch: function () {
            var _this = this;
            return idm.serviceCall({
                        url: '/dbTypes'
                    })
                    .then(function (qry) {
                        _this.reset(_.map(qry.result, function (r) {
                            r.id = r.db_type_id;
                            return new DBType(r);
                        }));
                        return _this;
                    });
        },
        getSelectedType: function () {
            return this.find(function (dbType) {
                return dbType.get("selected");
            });
        },
        setSelectedType: function (db_type_id, silentSelected) {
            this.each(function (dbType) {
                dbType.set({"selected": (dbType.id === db_type_id)}, {silent: true});
            });
            if (!silentSelected) {
                this.trigger("change");
            }
        }

    });

});
