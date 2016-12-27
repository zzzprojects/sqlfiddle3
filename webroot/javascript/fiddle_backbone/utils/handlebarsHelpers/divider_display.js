define(["Handlebars"], function (Handlebars) {


    Handlebars.registerHelper("divider_display", function(colWidths) {
        var padding = [];

        padding.length = colWidths[this.index] + 3;

        return padding.join('-') + "|";

    });

    // returns nothing
});