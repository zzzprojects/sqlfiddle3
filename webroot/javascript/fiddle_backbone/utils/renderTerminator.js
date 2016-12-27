define ([], function () {

    var renderTerminator = function(parentPanel, selectedTerminator){
        var mainBtn = parentPanel.find('.terminator a.btn');
        mainBtn.html(mainBtn.html().replace(/\[ .+ \]/, '[ ' + selectedTerminator + ' ]'));
        parentPanel.find(".terminator").data("statement_separator", selectedTerminator);
    }

    return renderTerminator;
});
