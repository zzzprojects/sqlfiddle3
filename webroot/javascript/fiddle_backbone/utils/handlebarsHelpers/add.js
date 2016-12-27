define(["Handlebars"], function (Handlebars) {

    Handlebars.registerHelper("add", function(value1, value2) {
        return value1+value2;
    });

    // returns nothing
});