define(["Handlebars"], function (Handlebars) {


    Handlebars.registerHelper("result_display_padded", function(colWidths) {
        var padding = [];

        padding.length = colWidths[this.index] - this.value.toString().length + 1;

        return padding.join(' ') + this.value.toString();
    });

    // returns nothing
});