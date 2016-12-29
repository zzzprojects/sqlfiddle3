define(["Backbone", "./UsedFiddle"], function (Backbone, UsedFiddle) {

    var MyFiddleHistory = Backbone.Collection.extend({
        model: UsedFiddle,
        comparator: function (m1,m2) {
            if (m1.get("last_used") === m2.get("last_used"))
                return 0;
            else if (m1.get("last_used") > m2.get("last_used"))
                return -1;
            else
                return 1;
        },
        insert: function (uf) {

            var existingFiddle = this.find(function (m) {
                return m.get("fragment") == uf.get("fragment");
            });

            if (existingFiddle) {
                existingFiddle.set("last_used", uf.get("last_used"));
                this.sort();
            } else {
                this.add(uf);
            }
            this.trigger("change");

        },
        initialize: function () {
            try {
                if (sessionStorage) {
                    var historyJSON = sessionStorage.getItem("fiddleHistory");
                    if (historyJSON && historyJSON.length) {
                        this.add($.parseJSON(historyJSON));
                    }
                }
            } catch (e) {
                // I guess sessionStorage isn't available
            }
        },
        sync: function () {
            try {
                if (sessionStorage) {
                    sessionStorage.setItem("fiddleHistory", JSON.stringify(this.toJSON()));
                }
            } catch (e) {
                // I guess sessionStorage isn't available
            }
        }
    });

    return MyFiddleHistory;

});