define(["Handlebars"], function (Handlebars) {

    Handlebars.registerHelper("code_format", function(original) {
        var code_format = [],
            lines = original.split("\n");
        for (var i = 0; i<lines.length; i++)
        {
            code_format.push("    " + lines[i]);
        }
        return code_format.join('\n');
    });

    // returns nothing
});