{% macro cleanup_product_name(column_name) %}
    REGEXP_REPLACE({{ column_name }}, '[^a-zA-Z0-9 ]', '')
{% endmacro %}