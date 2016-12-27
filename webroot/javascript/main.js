
requirejs.config({
    paths: {
        jquery: '../node_modules/jquery/dist/jquery',
        jqBlockUI: '../node_modules/block-ui/jquery.blockUI',
        jqCookie: '../node_modules/jquery.cookie/jquery.cookie',
        underscore: '../node_modules/lodash/index',
        text: '../node_modules/requirejs-text/text',
        codemirror: '../node_modules/codemirror/lib/codemirror',
        codemirror_sql: '../node_modules/codemirror/mode/sql/sql',
        Backbone: '../node_modules/backbone/backbone',
        Handlebars: '../node_modules/handlebars/dist/handlebars',
        md5: '../node_modules/blueimp-md5/js/md5',
        Bootstrap: 'libs/bootstrap.min',
        DateFormat: 'libs/date.format',
        XPlans: 'libs/xplans',
        DDLBuilder: 'libs/ddl_builder',
        utils: 'fiddle_backbone/utils'
    },
    map: {
        "*": {
            "../../lib/codemirror": "codemirror"
        }
    },
    shim: {
        DateFormat: {
            exports: 'dateFormat'
        },
        'XPlans/oracle/loadswf': {
            deps: ['XPlans/oracle/flashver'],
            exports: "loadswf"
        },
        'XPlans/mssql': {
            exports: "QP"
        },
        jqBlockUI: ['jquery'],
        jqCookie: ['jquery'],
        Bootstrap: ['jquery']
    }
});

require([
        'jquery',
        'underscore',
        'fiddle_backbone/app',
        'DDLBuilder/ddl_builder',

        'Bootstrap',
        'jqBlockUI',
        'jqCookie',

        'utils/handlebarsHelpers/divider_display',
        'utils/handlebarsHelpers/each_simple_value_with_index',
        'utils/handlebarsHelpers/each_with_index',
        'utils/handlebarsHelpers/result_display_padded',
        'utils/handlebarsHelpers/result_display',
        'utils/handlebarsHelpers/code_format',
        'utils/handlebarsHelpers/add'
    ],
    function($, _, App, ddl_builder) {

    $.blockUI.defaults.overlayCSS.cursor = 'auto';
    $.blockUI.defaults.css.cursor = 'auto';

    fiddleBackbone = App.initialize();

    // Now follows miscellaneous UI event bindings



    /* TEXT TO DDL */

    $("#textToDDLModal .btn").click(function (e){
        e.preventDefault();

        var builder = new ddl_builder({
                tableName: $("#tableName").val()
            })
            .setupForDBType(fiddleBackbone.dbTypes.getSelectedType().get("simple_name"), fiddleBackbone.schemaDef.get('statement_separator'));

        var ddl = builder.parse($("#raw").val());

        $("#parseResults").text(ddl);

        if ($(this).attr('id') == 'appendDDL')
        {
            fiddleBackbone.schemaDef.set("ddl", fiddleBackbone.schemaDef.get("ddl") + "\n\n" + ddl);
            fiddleBackbone.schemaDef.trigger("reloaded");
            $('#textToDDLModal').modal('hide');
        }
    });


    /* FULLSCREEN EDITS */

    function toggleFullscreenNav(option)
    {

        if ($("#exit_fullscreen").css('display') == "none")
        {
            $("body").css("overflow-y", "hidden");
            $(".navbar-fixed-top").css("position", "fixed").css("margin", 0);

            $("#exit_fullscreen").css('display', 'block');
            $("#exit_fullscreen span").text("Exit Fullscreen " + option);
            $(".nav-collapse, .btn-navbar, #db_type_label_collapsed .navbar-text").css('display', 'none');
        }
        else
        {
            $("body").css("overflow-y", "auto");
            $("body").css("height", "100%");
            $(".navbar-fixed-top").css("position", "").css("margin", "");

            $("#exit_fullscreen").css('display', 'none');
            $(".nav-collapse, .btn-navbar, #db_type_label_collapsed .navbar-text").css('display', '');
        }

    }

    $("#exit_fullscreen").on('click', function (e) {
        e.preventDefault();

        fiddleBackbone.schemaDefView.editor.setFullscreen(false);
        fiddleBackbone.queryView.editor.setFullscreen(false);

        toggleFullscreenNav('');
        resizeLayout();
    });

    $("#schemaFullscreen").on('click', function (e) {
        e.preventDefault();

        fiddleBackbone.schemaDefView.editor.setFullscreen(true);

        toggleFullscreenNav('Schema Editor');
    });


    $("#queryFullscreen").on('click', function (e) {
        e.preventDefault();

        fiddleBackbone.queryView.editor.setFullscreen(true);

        toggleFullscreenNav('Query Editor');
    });


    /* SCHEMA BROWSER */

    $("#schemaBrowser").on('click', function (e) {
        e.preventDefault();
        if (!$(this).attr('disabled')) {
            $('#fiddleFormDDL .CodeMirror, .ddl_actions').css('display', 'none');
            $('#browser, .browser_actions').css('display', 'block');
        }
    });

    $("#browser").on('click', '.tables a', function (e) {
        e.preventDefault();
        $('i', this).toggleClass("icon-minus icon-plus");
        $(this).siblings('.columns').toggle();
    });

    $("#ddlEdit").on('click', function (e) {
        e.preventDefault();
        $('#fiddleFormDDL .CodeMirror, .ddl_actions').css('display', 'block');
        $('#browser, .browser_actions').css('display', 'none');

    })


    /* RESIZING UI*/
    function resizeLayout(){

        var wheight = $(window).height() - 165;
        if (wheight > 400) {
            var container_width = $("#schema-output").width();


            $('#schema-output').height((wheight - 10) * 0.7);
            $('#output').css("min-height", ((wheight - 10) * 0.3) + "px");


            if (!fiddleBackbone.schemaDefView.editor.isFullscreen()) {
                $('#fiddleFormDDL .CodeMirror-scroll').css('height', ($('#fiddleFormDDL').height() - (5 + $('#fiddleFormDDL .action_buttons').height())) + "px");
                $('#schema_ddl').css('height', ($('#fiddleFormDDL').height() - (15 + $('#fiddleFormDDL .action_buttons').height())) + "px");
                $('#fiddleFormDDL .CodeMirror-scroll .CodeMirror-gutter').height($('#fiddleFormDDL .CodeMirror-scroll').height() - 2);
            }
            else {
                $('#fiddleFormDDL .CodeMirror-scroll, #schema_ddl').css('height', $(window).height() + "px");
                $('#fiddleFormDDL .CodeMirror-scroll .CodeMirror-gutter').height('height', $(window).height() + "px");

            }

            // textarea sql
            if (!fiddleBackbone.queryView.editor.isFullscreen()) {
                $('#fiddleFormSQL .CodeMirror-scroll').css('height', ($('#fiddleFormSQL').height() - (5 + $('#fiddleFormSQL .action_buttons').height())) + "px");
                $('#sql').css('height', ($('#fiddleFormSQL').height() - (15 + $('#fiddleFormSQL .action_buttons').height())) + "px");
                $('#fiddleFormSQL .CodeMirror-scroll .CodeMirror-gutter').height($('#fiddleFormSQL .CodeMirror-scroll').height() - 2);
            }
            else {

                $('#fiddleFormSQL .CodeMirror-scroll, #sql').css('height', $(window).height() + "px");
                $('#fiddleFormSQL .CodeMirror-scroll .CodeMirror-gutter').css('height', $(window).height() + "px");

            }


    //        $('#sql').width($('#fiddleFormSQL').width() - 10);
    //        $('#schema_ddl').width($('#fiddleFormDDL').width() - 10);

            $('#browser').height($('#fiddleFormDDL .CodeMirror-scroll').height());

            var adjustBlockMsg = function (blockedObj) {
                var msgSize =
                    {
                        "height": $(".blockMsg", blockedObj).height(),
                        "width": $(".blockMsg", blockedObj).width()
                    };
                var objSize =
                    {
                        "height": $(blockedObj).height(),
                        "width": $(blockedObj).width()
                    };

                $(".blockMsg", blockedObj)
                    .css("top", (objSize.height-msgSize.height)/2)
                    .css("left", (objSize.width-msgSize.width)/2);

            }

            adjustBlockMsg($("div.sql.panel"));
            adjustBlockMsg($("#output"));

            fiddleBackbone.schemaDefView.refresh();
            fiddleBackbone.queryView.refresh();
        }
    }


    $(window).bind('resize', resizeLayout);
    setTimeout(resizeLayout, 1);


    /* COLLAPSING NAV (for responsive UI) */

    $(".nav").on('click', 'a', function (e) {

        if ($(this).parent('li').attr('id') !== 'db_type_id' &&
            $(this).parent('li').attr('id') !== 'userOptions') {

            $(".nav-collapse.in").collapse('hide');

        } else {
            $(this).parents('div.nav-collapse.in').css('height', 'auto');
        }
    });

});
