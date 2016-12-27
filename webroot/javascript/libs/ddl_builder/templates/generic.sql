CREATE TABLE {{{tablePrefix}}}{{tableName}}{{{tableSuffix}}}
    ({{#each_with_index columns}}{{#if index}}, {{/if}}{{{../fieldPrefix}}}{{name}}{{{../fieldSuffix}}} {{db_type}}{{/each_with_index}})
{{separator}}
    
INSERT INTO {{{tablePrefix}}}{{tableName}}{{{tableSuffix}}}
    ({{#each_with_index columns}}{{#if index}}, {{/if}}{{{../fieldPrefix}}}{{name}}{{{../fieldSuffix}}}{{/each_with_index}})
VALUES
    {{#each_with_index data}}{{#if index}},
    {{/if}}({{#each_with_index r}}{{#if index}}, {{/if}}{{formatted_field ../..}}{{/each_with_index}}){{/each_with_index}}
{{separator}}
