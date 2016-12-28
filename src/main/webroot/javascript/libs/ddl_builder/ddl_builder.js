/*
 * DDL Builder
 * Copyright Jake Feasel, 2012
 * Released under MIT license
 * For questions email admin at sqlfiddle dot com
 * http://github.com/jakefeasel/DDLBuilder
 */

define(
    [
     "jquery",
     "Handlebars",
     "DateFormat",
     'text!./templates/generic.sql',
     'text!./templates/oracle.sql',
     'text!./templates/sqlite.sql'
     ],
    function ($, Handlebars, dateFormat, generic_template, oracle_template, sqlite_template) {

    ddl_builder = function (args) {
        if (!args) args = {};
        // output settings
        this.fieldPrefix = '';
        this.fieldSuffix = '';
        this.tablePrefix = '';
        this.tableSuffix = '';


        this.dateFormatMask = "yyyy-mm-dd HH:MM:ss";

        this.charType = 'varchar';
        this.intType = 'int';
        this.floatType = 'numeric';
        this.dateType = 'datetime';

        // input settings
        this.valueSeparator = '';

        this.column_count = 0;
        this.definition = {
                tableName: "Table1",
                columns: [/* sample column structure
                            {
                                name: 'id',
                                type: 'int',
                                length: '',
                                db_type: 'int4'
                            },
                            {
                                name: 'name',
                                type: 'char',
                                length: 20,
                                db_type: 'varchar(20)'
                            }
                             */],
                data: [/* sample data structure
                             // r for "row", v for "value"
                            {r:[{v:1},{v:'Jake'}]},
                            {r:[{v:2},{v:'Rachel'}]},
                            {r:[{v:3},{v:'Andrew'}]},
                            {r:[{v:4},{v:'Ada'}]},
                            {r:[{v:5},{v:'Lucy O\'Malley'}]}


                         */]
            };


        this.ddlTemplate = generic_template;

        this.compiledTemplate = Handlebars.compile(this.ddlTemplate);
        this.setup(args);
        return this;
    };

    ddl_builder.prototype.setup = function (settings) {
        for (var opt in settings)
        {
            this[opt] = settings[opt];
        }

        if (settings["ddlTemplate"])
            this.compiledTemplate = Handlebars.compile(this.ddlTemplate);

        if (settings["tableName"])
            this.definition.tableName = settings.tableName;

        return this;
    };

    ddl_builder.prototype.setupForDBType = function (type,separator) {

        switch (type)
        {
            case 'SQL Server':
                this.setup({
                                statement_separator: separator,
                                fieldPrefix: '[',
                                fieldSuffix: ']',
                                tablePrefix: '[',
                                tableSuffix: ']'
                            });
            break;

            case 'MySQL':
                this.setup({
                                statement_separator: separator,
                                fieldPrefix: '`',
                                fieldSuffix: '`',
                                tablePrefix: '`',
                                tableSuffix: '`'
                            });
            break;
            case 'PostgreSQL':
                this.setup({
                                statement_separator: separator,
                                dateType: 'timestamp',
                                fieldPrefix: '"',
                                fieldSuffix: '"'
                            });
            break;

            case 'Oracle':
                var template = oracle_template;

                    this.setup({
                                dateFormatMask: 'dd-mmm-yyyy hh:MM:ss TT',
                                statement_separator: separator,
                                ddlTemplate: template,
                                dateType: 'timestamp',
                                charType: 'varchar2',
                                fieldPrefix: '"',
                                fieldSuffix: '"'
                            });
            break;



            case 'SQLite':
                var template = sqlite_template;


                    this.setup({
                                fieldPrefix: '"',
                                fieldSuffix: '"',
                                tablePrefix: '"',
                                tableSuffix: '"',
                                statement_separator: separator,
                                ddlTemplate: template,
                                dateType: 'DATE',
                                charType: 'TEXT',
                                intType: 'INTEGER',
                                floatType: 'REAL'
                            });
            break;


        }
        return this;
    };

    ddl_builder.prototype.populateDBTypes = function () {
        for (var i=0;i<this.definition.columns.length;i++)
        {
            if (this.definition.columns[i].type == 'charType')
                this.definition.columns[i].db_type = this[this.definition.columns[i].type] + "(" + this.definition.columns[i].length + ")";
            else
                this.definition.columns[i].db_type = this[this.definition.columns[i].type];
        }

        this.definition.dateFormatMask = this.dateFormatMask;

    };

    ddl_builder.prototype.populateWrappers = function () {
        this.definition.fieldPrefix = this.fieldPrefix;
        this.definition.fieldSuffix = this.fieldSuffix;
    };


    ddl_builder.prototype.guessValueSeparator = function (raw) {


        var lines = raw.split("\n");
        var header_found = false, column_count = 0, found_separator = '';

        for (var i = 0; i<lines.length; i++)
        {
            if (lines[i].search(/[A-Z0-9_]/i) != -1 && !header_found) // if this line contains letters/numbers/underscores, then we can assume we've hit the header row
            {
                var chunks = $.trim(lines[i]).match(/([A-Z0-9_]+ ?)+([^A-Z0-9_]*)/gi);
                if (chunks.length == 1)
                {
                    chunks = $.trim(lines[i]).match(/([A-Z0-9_]+ ?)+?([^A-Z0-9_]*)/gi);
                }

                header_found = true;

                for (var j = 0; j < chunks.length; j++)
                {
                    var this_separator = chunks[j].match(/[A-Z0-9_]+([^A-Z0-9_]*)$/i).pop(); // gets the last returned value from regexp

                    if (this_separator.search(/^\s\s+$/) != -1)
                        this_separator = new RegExp("\\s\\s+");
                    else if (this_separator.search(/^\t+$/) != -1)
                        this_separator = new RegExp("\\t+");
                    else if (this_separator.search(/^\s+$/) != -1)
                        this_separator = new RegExp("\\s+");
                    else
                        this_separator = $.trim(this_separator);

                    if (this_separator instanceof RegExp || this_separator.length)
                    {
                        if (!(found_separator instanceof RegExp) && !found_separator.length)
                            found_separator = this_separator;
                        else if (found_separator.toString() != this_separator.toString())
                            return {status: false, message: 'Unable to find consistent column separator in header row'}; // different separators founds?
                    }
                    else if (! (this_separator instanceof RegExp) && !(found_separator instanceof RegExp) && !found_separator.length)
                    {
                        found_separator = "\n";
                    }

                }
                if (found_separator instanceof RegExp || found_separator.length)
                    column_count = $.trim(lines[i]).split(found_separator).length;
                else
                    column_count = 1;


            }
            else if (lines[i].search(/[A-Z0-9_]/i) != -1)
            {
                if ($.trim(lines[i]).split(found_separator).length != column_count &&
                        (
                                found_separator.toString() != /\s\s+/.toString() ||
                                $.trim(lines[i]).split(/\s+/).length != column_count
                        )
                    )
                    return {status: false, message: 'Line ' + i + ' does not have the same number of columns as the header, based on separator "' + found_separator + '".'};

            }

        }
        return {status: true, separator: found_separator, column_count: column_count};
    };

    ddl_builder.prototype.parse = function (raw) {

        /*
         * brokenDateChecker is used to eliminate strings that for some reason pass Chrome's standard of a 'valid' date, and
         * yet are not worth considering as such. Chrome will take garbage like 'ABC 1' as an input to `new Date()`, returning
         * January 1st 2001 for some reason.  This regex will allow a lot of fuzzy input formats to still pass, but only really
         * keep meaningful entries. This isn't a problem for Firefox or Safari. I haven't checked IE.
         */
        var brokenDateChecker = /^(?!Jan)(?!Feb)(?!Mar)(?!Apr)(?!May)(?!Jun)(?!Jul)(?!Aug)(?!Sep)(?!Oct)(?!Nov)(?!Dec)[A-Za-z\ \-\_]+\d+\s*$/,
            result = {}, lines = [], elements = [], tmpRow = [], i = 0, j = 0, value = "";

        if (!this.valueSeparator.length)
        {
            result = this.guessValueSeparator(raw);
            if (!result.status)
                return "ERROR! " + result.message;
            else
            {
                this.column_count = result.column_count;
                this.valueSeparator = result.separator;
            }
        }

        lines = raw.split("\n");

        for (i=0;i<lines.length;i++)
        {
            elements = $.trim(lines[i]).split(this.valueSeparator);

            if ($.trim(lines[i]).length &&
                    (
                        elements.length == this.column_count ||
                        (
                                this.valueSeparator.toString() == /\s\s+/.toString() &&
                                (elements =  $.trim(lines[i]).split(/\s+/)).length == this.column_count
                        )
                    )
                )
            {
                if (! this.definition.columns.length)
                {
                    for (j = 0; j < elements.length; j++)
                    {
                            value = $.trim(elements[j]);
                            if (value.length)
                                this.definition.columns.push({"name": value});
                            else
                                this.definition.columns.push(false);
                    }
                }
                else
                {
                    tmpRow = [];
                    for (j = 0; j < elements.length; j++)
                    {
                        if (this.definition.columns[j] !== false)
                        {
                            value = $.trim(elements[j]).replace(/'/g, "''");

                            // if the current field is not a number, or if we have previously decided that this one of the non-numeric field types...
                            if (isNaN(value) || this.definition.columns[j].type == 'dateType' || this.definition.columns[j].type == 'charType')
                            {

                                // if we haven't previously decided that this is a character field, and it can be cast as a date, then declare it a date
                                if (this.definition.columns[j].type != 'charType' && !(isNaN(Date.parse("UTC:" + value)) || value.match(brokenDateChecker)) )
                                    this.definition.columns[j].type = "dateType";
                                else
                                    this.definition.columns[j].type = "charType";
                            }
                            else // this must be some kind of number field
                            {
                                if (this.definition.columns[j].type != 'floatType' && value % 1 != 0)
                                    this.definition.columns[j].type = 'floatType';
                                else
                                    this.definition.columns[j].type = 'intType';
                            }

                            if (!this.definition.columns[j].length || value.length > this.definition.columns[j].length)
                            {
                                this.definition.columns[j].length = value.length;
                            }

                            tmpRow.push({v:value});
                        }

                    }
                    this.definition.data.push({r: tmpRow});

                }

            }
        }
        this.populateDBTypes();
        this.populateWrappers();
        return this.render();
    };

    /* HandlebarsJS-using code below */

    Handlebars.registerHelper("formatted_field", function(root) {

        var colType = '';
        var index = -1;
        for (var j = 0; j < root.columns.length; j++)
        {
            if (root.columns[j])
                index++;

            if (index == this.index)
            {
                colType = root.columns[j].type;
                break;
            }
        }


        if (!this.v.length || this.v.toUpperCase() == 'NULL')
            return 'NULL';
        if (colType == 'charType')
            return new Handlebars.SafeString("'" + this.v + "'");

        if (colType == 'dateType')
            return new Handlebars.SafeString("'" + dateFormat("UTC:" + this.v, root.dateFormatMask) + "'");

        return this.v;
    });

    Handlebars.registerHelper("column_name_for_index", function(root) {
        return root.columns[this.index].name;
    });


    ddl_builder.prototype.render = function () {
        return this.compiledTemplate($.extend(this.definition, {"separator": this.statement_separator}));
    };

    return ddl_builder;

});
