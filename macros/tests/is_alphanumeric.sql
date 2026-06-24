{% test is_alphanumeric(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} IS NOT NULL
  and {{ column_name }} != REGEXP_REPLACE({{ column_name }}, '[^a-zA-Z0-9 ]', '')

{% endtest %}