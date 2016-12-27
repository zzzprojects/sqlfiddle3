define ([
        "jquery", 
        "Backbone", 
        "Handlebars", 
        "utils/fiddleEditor", 
        "utils/renderTerminator",
        "text!fiddle_backbone/templates/schemaOutput.html", 
        "text!fiddle_backbone/templates/schemaBrowser.html"
    ],
    function ($,Backbone,Handlebars,fiddleEditor,renderTerminator,schemaOutputTemplate,schemaBrowserTemplate) {

    var SchemaDefView = Backbone.View.extend({

        initialize: function (options) {
            this.options = options;
            this.editor = new fiddleEditor(this.id,this.handleSchemaChange, this,
                                            _.bind(function () {
                                                this.model.build();
                                            }, this));

            this.compiledOutputTemplate = Handlebars.compile(schemaOutputTemplate);

            this.compiledSchemaBrowserTemplate = Handlebars.compile(schemaBrowserTemplate);

        },
        handleSchemaChange: function () {

            if (this.model.get("ddl") != this.editor.getValue() || this.model.get("statement_separator") != $(".panel.schema .terminator").data("statement_separator"))
            {
                this.model.set({
                    "ddl":this.editor.getValue(),
                    "statement_separator":$(".panel.schema .terminator").data("statement_separator"),
                    "ready": false
                });

                $(".schema .helpTip").css("display",  this.model.get("ddl").length ? "none" : "block");
                $(".sql .helpTip").css("display",  (!this.model.get("ready") || this.model.get("loading")) ? "none" : "block");

            }

        },
        render: function () {
            this.editor.setValue(this.model.get("ddl"));
            this.updateDependents();
            renderTerminator($(".panel.schema"), this.model.get("statement_separator"));
        },
        renderOutput: function() {
            this.options.output_el.html(
                this.compiledOutputTemplate(this.model.toJSON())
            );
        },
        renderSchemaBrowser: function () {
            this.options.browser_el.html(
                this.compiledSchemaBrowserTemplate({
                    "objects": this.model.get('schema_structure')
                })
            );
        },
        refresh: function () {
            this.editor.refresh();
        },
        updateDependents: function () {

            if (this.model.get("ready"))
            {
                $(".needsReadySchema").unblock();
                $("#schemaBrowser").attr("disabled", false);
                $(".schema .helpTip").css("display",  "none");
                //$(".sql .helpTip").css("display",  (this.model.get('loading') || window.query.get("sql").length) ? "none" : "block");
            }
            else
            {
                $(".needsReadySchema").block({ message: "Please build schema." });
                $("#schemaBrowser").attr("disabled", true);
                $(".schema .helpTip").css("display",  (this.model.get('loading') || this.model.get("ddl").length) ? "none" : "block");

            }

        }

    });

    return SchemaDefView;

});