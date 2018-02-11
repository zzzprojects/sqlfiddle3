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
        getLatestDBTypeForSimpleName: function (simple_name) {
            simple_name = simple_name || this.getSelectedType().get('simple_name');
            return this
            .filter(function (dbType) {
                return  dbType.get("simple_name") === simple_name &&
                        dbType.get("num_hosts") > 0;
            })
            // sorts the resulting list of dbTypes by full_name in descending order
            // assumes that the versions of a given simple_name set are sortable alphabetically
            .sort(function (dbTypeA, dbTypeB) {
                return dbTypeA.get("full_name") > dbTypeB.get("full_name") ? -1 : 1;
            })[0];
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
