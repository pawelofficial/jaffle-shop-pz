{% test model_exists(model) %}

select 1 as missing
where not exists (
    select 1
    from information_schema.tables
    where upper(table_name)    = upper('{{ model.identifier }}')
      and upper(table_schema)  = upper('{{ model.schema }}')
      and upper(table_catalog) = upper('{{ model.database }}')
)

{% endtest %}