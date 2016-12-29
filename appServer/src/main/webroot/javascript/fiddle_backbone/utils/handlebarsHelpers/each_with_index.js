define(["Handlebars"], function (Handlebars) {

    Handlebars.registerHelper("each_with_index", function(array, fn) {
        var buffer = "";
        var k=0;
        for (var i = 0, j = array.length; i < j; i++) {
            if (array[i])
            {
                var item = array[i];

                // stick an index property onto the item, starting with 0
                item.index = k;

                item.first = (k == 0);
                item.last = (k == array.length);

                // show the inside of the block
                buffer += fn.fn(item);

                k++;
            }
        }

        // return the finished buffer
        return buffer;

    });

    // returns nothing
});