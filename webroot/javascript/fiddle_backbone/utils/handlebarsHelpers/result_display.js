define(["jquery","Handlebars"], function ($,Handlebars) {


    Handlebars.registerHelper("result_display", function(value) {
        // thanks to John Gruber for this regexp http://daringfireball.net/2010/07/improved_regex_for_matching_urls
        // also to "Searls" for his port to JS https://gist.github.com/1033143
        var urlRegexp = /\b((?:https?:\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?������]))/ig;

        if ($.isPlainObject(value))
            return JSON.stringify(value, null, 4);
        else if (value == null)
            return "(null)";
        else if (value === false)
            return "false";
        else if (typeof value === "string" && value.match(urlRegexp) && Handlebars.Utils.escapeExpression(value) == value)
            return new Handlebars.SafeString(value.replace(urlRegexp, "<a href='$1' target='_new'>$1</a>"));
        else
            return value;
    });

    // returns nothing
});