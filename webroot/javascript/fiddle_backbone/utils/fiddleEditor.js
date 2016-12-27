define(["codemirror", "codemirror_sql", "jquery"], function (CodeMirror, sqlMode, $){

    var fiddleEditor = function (domID, changeHandler, viewRef, runHandler) {

        $.extend(this, CodeMirror.fromTextArea(document.getElementById(domID), {
            mode: "text/x-mysql",
            matchBrackets: true,
            extraKeys: {Tab: "indentMore"},
            lineNumbers: true
        }));

        $(this.getWrapperElement()).on("keypress", function (e) {
            if (e.keyCode == 13 && e.ctrlKey && runHandler) {
                e.preventDefault();
                runHandler();
            }
        });

        $(this.getWrapperElement()).on("change keyup", function (e) {
            changeHandler.call(viewRef);
        });

        return this;
    };

    fiddleEditor.prototype = $.extend({}, CodeMirror.prototype);

    fiddleEditor.prototype.isFullscreen = function () {
        return $(this.getScrollerElement()).hasClass('CodeMirror-fullscreen')
    }
    fiddleEditor.prototype.setFullscreen = function (fullscreenMode) {
        if (fullscreenMode)
        {
            var wHeight = $(window).height() - 40;
            $(this.getScrollerElement()).addClass('CodeMirror-fullscreen').height(wHeight);
            $(this.getGutterElement()).height(wHeight);
        }
        else
        {
            $(this.getScrollerElement()).removeClass('CodeMirror-fullscreen');
            $(this.getGutterElement()).css('height', 'auto');
            $(this.getScrollerElement()).css('height', '200px');
        }
    }

    return fiddleEditor;

});
