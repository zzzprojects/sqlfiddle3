CREATE TABLE {{{tablePrefix}}}{{tableName}}{{{tableSuffix}}}
    ({{#each_with_index columns}}{{#if index}}, {{/if}}{{{../fieldPrefix}}}{{name}}{{{../fieldSuffix}}} {{db_type}}{{/each_with_index}})
{{separator}}

INSERT ALL {{#each_with_index data}}
    INTO {{{../tablePrefix}}}{{../tableName}}{{{../tableSuffix}}} ({{#each_with_index r}}{{#if index}}, {{/if}}{{{../../fieldPrefix}}}{{column_name_for_index ../..}}{{{../../fieldSuffix}}}{{/each_with_index}})
         VALUES ({{#each_with_index r}}{{#if index}}, {{/if}}{{formatted_field ../..}}{{/each_with_index}}){{/each_with_index}}
SELECT * FROM dual
{{separator}}