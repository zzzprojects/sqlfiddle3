define ([
        "jquery",
        "underscore",
        "Backbone",
        "Handlebars",
        "utils/fiddleEditor",
        "utils/renderTerminator",
        'XPlans/mssql',
        "text!fiddle_backbone/templates/queryTabularOutput.html",
        "text!fiddle_backbone/templates/queryPlaintextOutput.html",
        "text!fiddle_backbone/templates/queryMarkdownOutput.html"
    ],
    function ($,_,Backbone,Handlebars,fiddleEditor,renderTerminator,QP,tabTemplate,plainTemplate,mdTemplate) {


    var QueryView = Backbone.View.extend({

        initialize: function (options) {
            this.options = options;
            this.editor = new fiddleEditor(this.id,this.handleQueryChange, this,
                                            _.bind(function () {
                                                this.model.execute();
                                            }, this));
            this.outputType = "tabular";
            this.compiledOutputTemplate = {};
            this.compiledOutputTemplate["tabular"] = Handlebars.compile(tabTemplate);
            this.compiledOutputTemplate["plaintext"] = Handlebars.compile(plainTemplate);
            this.compiledOutputTemplate["markdown"] = Handlebars.compile(mdTemplate);

        },
        setOutputType: function (type) {
            this.outputType = type;
        },
        handleQueryChange: function (e) {

            var schemaDef = this.model.get("schemaDef");

            this.model.set({
                "sql":this.editor.getValue()
            });
            $(".sql .helpTip").css("display",  (!schemaDef.get("ready") || schemaDef.get("loading") || this.model.get("sql").length) ? "none" : "block");
        },
        render: function () {
            this.editor.setValue(this.model.get("sql"));

            if (this.model.id)
                this.renderOutput();

            renderTerminator($(".panel.sql"), this.model.get("statement_separator"));
        },
        renderOutput: function() {
            var thisModel = this.model;
            var inspectedData = this.model.toJSON();
            var latestDBType = this.options.dbTypes.getLatestDBTypeForSimpleName();

            /* This loop determines the max width of each column, so it can be padded appropriately (if needed) */
            _.each(inspectedData.sets, function (set, sidx) {
                if (set.RESULTS)
                {
                    // Initialize the column widths with the length of the headers
                    var columnWidths = _.map(set.RESULTS.COLUMNS, function (col) {
                        return col.length;
                    });

                    // then increase the width as needed if a bigger value is found in the data
                    _.each(set.RESULTS.DATA, function (row,ridx) {

                        row = _.map(row, function (value) {
                            if (value === null) {
                                return "(null)";
                            } else {
                                return value;
                            }
                        });

                        set.RESULTS.DATA[ridx] = row;

                        columnWidths = _.map(row, function (col,cidx) {
                            return _.max([col.toString().length,columnWidths[cidx]]) ;
                        });
                    });
                inspectedData.sets[sidx].RESULTS.COLUMNWIDTHS = columnWidths;
                }
            });
            inspectedData["latestDBType"] = latestDBType ? latestDBType.toJSON() : null;
            inspectedData["schemaDef"] = this.model.get("schemaDef").toJSON();
            inspectedData["schemaDef"]["dbType"] = this.model.get("schemaDef").get("dbType").toJSON();
            inspectedData["schemaDef"]["dbType"]["isSQLServer"] = this.model.get("schemaDef").get("dbType").get("simple_name") == "SQL Server";
            inspectedData["schemaDef"]["dbType"]["isPostgreSQL"] = this.model.get("schemaDef").get("dbType").get("simple_name") == "PostgreSQL";

            this.options.output_el.html(
                this.compiledOutputTemplate[this.outputType](inspectedData)
            );


            this.options.output_el.find("a.executionPlanLink").click(function (e) {
                e.preventDefault();
                $("i", this).toggleClass("icon-minus icon-plus");
                $(this).closest(".set").find(".executionPlan").toggle();

                if ($("i", this).hasClass("icon-minus") &&
                    thisModel.get("schemaDef").get("dbType").get("simple_name") == 'SQL Server'
                   )
                {
                    QP.drawLines($(this).closest(".set").find(".executionPlan div"));
                }


            });

            this.options.output_el.find(".convert-to-latest").click(_.bind(function (e) {
                e.preventDefault();
                this.options.dbTypes.setSelectedType(latestDBType.get('db_type_id'));
                this.model.get("schemaDef").set('dbType', latestDBType).build().then(_.bind(function () {
                    if (this.model.get("schemaDef").get("ready")) {
                        this.model.execute();
                    }
                }, this));
            }, this));

        },
        refresh: function () {
            this.editor.refresh();
        },
        checkForSelectedText: function () {
            if (this.editor.somethingSelected())
                this.model.set("sql", this.editor.getSelection());
            else
                this.model.set("sql", this.editor.getValue());
        }

    });

    return QueryView;

});
