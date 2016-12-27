define([
    'utils/browserEngines/engines',

    './models/OpenIDConnectProviders',
    './models/UsedFiddle',
    './models/MyFiddleHistory',
    './models/DBTypesList',
    './models/SchemaDef',
    './models/Query',

    './views/DBTypesList',
    './views/SchemaDef',
    './views/Query',
    './views/LoginDialog',
    './views/UserOptions',
    './views/MyFiddleDialog',

    './router',
    'utils/renderTerminator',
    'utils/openidconnect',
    'underscore', 'jquery'
], function (
        browserEngines,
        OpenIDConnectProviers, UsedFiddle, MyFiddleHistory, DBTypesList, SchemaDef, Query,
        DBTypesListView, SchemaDefView, QueryView, LoginDialog, UserOptions, MyFiddleDialog,
        Router, renderTerminator, openidconnect,
        _, $
    ) {

var obj = {

    initialize : function() {

        var router = {};

        var oidc = new OpenIDConnectProviers();

        var myFiddleHistory = new MyFiddleHistory();

        var dbTypes = new DBTypesList();

        var schemaDef = new SchemaDef({browserEngines: browserEngines});

        var query = new Query({
            "schemaDef": schemaDef
        });

        var dbTypesListView = new DBTypesListView({
            el: $("#db_type_id")[0],
            collection: dbTypes
        });

        var schemaDefView = new SchemaDefView({
            id: "schema_ddl",
            model: schemaDef,
            output_el: $("#output"),
            browser_el: $("#browser")
        });

        var queryView = new QueryView({
            id: "sql",
            model: query,
            output_el: $("#output")
        });

        var loginDialog = new LoginDialog({
            el: $("#loginModal")[0],
            collection: oidc
        });

        var myFiddleDialog = new MyFiddleDialog({
            el: $("#myFiddlesModal")[0],
            collection: myFiddleHistory
        });

        var userOptions = new UserOptions({
            el: $("#userOptions .dropdown-menu")[0],
            oidc: oidc,
            myFiddleDialog: myFiddleDialog
        });

        /* UI Changes */
        dbTypes.on("change", function () {
        // see also the router function defined below that also binds to this event
            dbTypesListView.render();
            if (schemaDef.has("dbType")) {
                schemaDef.set("ready", (schemaDef.get("short_code").length && schemaDef.get("dbType").id === this.getSelectedType().id));
            }
        });

        schemaDef.on("change", function () {
            if (this.hasChanged("ready")) {
                schemaDefView.updateDependents();
            }

            if (this.hasChanged("errorMessage")) {
                schemaDefView.renderOutput();
            }

            if (this.hasChanged("schema_structure")) {
                schemaDefView.renderSchemaBrowser();
            }
        });

        schemaDef.on("reloaded", function () {
            this.set("dbType", dbTypes.getSelectedType());
            schemaDefView.render();
        });

        query.on("reloaded", function () {
            this.set({"pendingChanges": false}, {silent: true});

            queryView.render();
        });

        schemaDef.on("built failed", function () {
        // see also the router function defined below that also binds to this event
            $("#buildSchema label").prop('disabled', false);
            $("#buildSchema label").html($("#buildSchema label").data("originalValue"));
            schemaDefView.renderOutput();
            schemaDefView.renderSchemaBrowser();
        });

        query.on("change", function () {
            if ((this.hasChanged("sql") || this.hasChanged("statement_separator")) && !this.hasChanged("id") && !this.get("pendingChanges"))
            {
                this.set({"pendingChanges": true}, {silent: true});
            }
        });

        query.on("executed", function () {
        // see also the router function defined below that also binds to this event
            var $button = $(".runQuery");
            $button.prop('disabled', false);
            $button.html($button.data("originalValue"));

            this.set({"pendingChanges": false}, {silent: true});
            queryView.renderOutput();
        });

        /* Non-view object event binding */
        $("#buildSchema").click(function (e) {
            var $button = $("label", this);
            e.preventDefault();

            if ($button.prop('disabled')) {
                return false;
            }

            $button.data("originalValue", $button.html());
            $button.prop('disabled', true).text('Building Schema...');

            schemaDef.build();
        });

        var handleRunQuery = function (e) {
            var $button = $(".runQuery");
            e.preventDefault();

            if ($button.prop('disabled')) return false;
            $button.data("originalValue", $button.html());
            $button.prop('disabled', true).text('Executing SQL...');

            queryView.checkForSelectedText();
            query.execute();
        };

        $(".runQuery").click(handleRunQuery);
        $(document).keyup(function (e) {
            if (e.keyCode == 116) // F5
            {
                e.preventDefault();
                handleRunQuery(e);
            }
        });

        $("#runQueryOptions li a").click(function (e) {
            e.preventDefault();
            queryView.setOutputType(this.id);
            queryView.renderOutput();
        });

        $("#queryPrettify").click(function (e) {
            var thisButton = $(this);
            thisButton.attr("disabled", true);
            e.preventDefault();
            $.post("index.cfm/proxy/formatSQL", {sql: query.get("sql")}, function (resp) {
                query.set({"sql": resp});
                query.trigger('reloaded');
                query.set({"pendingChanges": true});

                thisButton.attr("disabled", false);
            });
        });

        $(".terminator .dropdown-menu a").on('click', function (e) {
            e.preventDefault();

            renderTerminator($(this).closest(".panel"), $(this).attr('href'));

            if ($(this).closest(".panel").hasClass("schema"))
            {
                schemaDefView.handleSchemaChange();
            }
            else // must be the query panel button
            {
                query.set({
                    "pendingChanges": true,
                    "statement_separator": $(this).attr('href')
                }, {silent: true});
            }

        });

        $("#output").on("click", ".depesz", function (e) {
            var fullTextPlan = $(this).closest(".set").find(".executionPlan tr:not(:first)").text();
            $(this).closest("form").find("[name=plan]").val(fullTextPlan);
        });

        $(window).bind('beforeunload', function () {
            if (query.get("pendingChanges"))
                return "Warning! You have made changes to your query which will be lost. Continue?'";
        });

        /* Data loading */
        dbTypes.on("reset", function () {
            // When the dbTypes are loaded, everything else is ready to go....
            router = Router.initialize(dbTypes, schemaDef, query, myFiddleHistory, dbTypesListView);

            if (this.length && !this.getSelectedType())
            {
                this.setSelectedType(this.first().id, true);
            }

            schemaDef.set({"dbType": this.getSelectedType()}, {silent: true});

            // make sure everything is up-to-date on the page
            dbTypesListView.render();
            schemaDefView.render();
            queryView.render();
        });

        oidc.on("reset", function () {
            // note that this isn't visible until the login button is clicked
            loginDialog.render();
        });

        myFiddleHistory.on("change reset remove", myFiddleHistory.sync, myFiddleHistory);


        /* Events which will trigger new route navigation */

        $("#clear").click(function (e) {
            e.preventDefault();
            schemaDef.reset();
            query.reset();
            $("body").unblock();
            router.navigate("!" + dbTypes.getSelectedType().id, {trigger: true});
        });

        $("#sample").click(function (e) {
            e.preventDefault();
            router.navigate("!" + dbTypes.getSelectedType().get("sample_fragment"), {trigger: true});
        });

        dbTypes.on("change", function () {
            dbTypesListView.render();
            if (
                    query.id &&
                    schemaDef.get("short_code").length &&
                    schemaDef.get("dbType").id === this.getSelectedType().id
                )
                router.navigate("!" + this.getSelectedType().id + "/" + schemaDef.get("short_code") + "/" + query.id);
            else if (
                    schemaDef.get("short_code").length &&
                    schemaDef.get("dbType").id == this.getSelectedType().id
                )
                router.navigate("!" + this.getSelectedType().id + "/" + schemaDef.get("short_code"));
            else
                router.navigate("!" + this.getSelectedType().id);

            schemaDef.set("dbType", this.getSelectedType());

        });

        schemaDef.on("built", function () {

            myFiddleHistory.insert(new UsedFiddle({
                "fragment": "!" + this.get("dbType").id + "/" + this.get("short_code"),
                "full_name": this.get("dbType").get("full_name"),
                "structure": this.get("schema_structure")
            }));

            router.navigate("!" + this.get("dbType").id + "/" + this.get("short_code"));
        });

        query.on("executed", function () {
            var schemaDef = this.get("schemaDef");

            if (this.id) {
                myFiddleHistory.insert(new UsedFiddle({
                    "fragment": "!" + schemaDef.get("dbType").id + "/" + schemaDef.get("short_code") + "/" + this.id,
                    "full_name": schemaDef.get("dbType").get("full_name"),
                    "structure": schemaDef.get("schema_structure"),
                    "sql": this.get("sql"),
                    "sets": _.map(this.get("sets"), function (set) {
                                return {
                                    "succeeded": set.SUCCEEDED,
                                    "statement_sql": set.STATEMENT.substring(0,400),
                                    "row_count": set.RESULTS.DATA.length,
                                    "columns": set.RESULTS.COLUMNS.join(", "),
                                    "error_message": set.ERRORMESSAGE
                                };
                            })
                }));

                router.navigate(
                    "!" + schemaDef.get("dbType").id + "/" + schemaDef.get("short_code") + "/" + this.id
                );
            }

        });

        dbTypes.fetch();

        openidconnect.getLoggedUserDetails().then(function (userInfo) {
            if (userInfo) {
                userOptions.renderAuthenticated(userInfo);
                myFiddleDialog.setAnonymous(false);
            } else {
                userOptions.renderAnonymous();
                myFiddleDialog.setAnonymous(true);
            }
        }, function () {
            userOptions.renderAnonymous();
            myFiddleDialog.setAnonymous(true);
        });

        _.extend(this, {
                dbTypes: dbTypes,
                schemaDef: schemaDef,
                schemaDefView: schemaDefView,
                queryView: queryView
            });

        return this;

        }

    };

    return obj;

});
