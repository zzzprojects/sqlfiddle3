define(["./OpenIDMResource", "Backbone"], function (idm, Backbone) {
    return Backbone.Collection.extend({
        fetch: function () {
            var _this = this;
            return idm.serviceCall({
                url: "/oidc"
            })
            .then(function (data) {
                _this.reset(_.map(data.resolvers, function (r) {
                    return new Backbone.Model(r);
                }));
                return _this;
            });
        }
    });
});
