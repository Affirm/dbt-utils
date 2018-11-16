{#
Pivot values from columns to rows.

Example Usage: {{ dbt_utils.unpivot(table=ref('users'), cast_to='integer', exclude=['id','created_at']) }}

Arguments:
    table: Table name, required.
    cast_to: The datatype to cast all unpivoted columns to. Default is varchar.
    exclude: A list of columns to exclude from the unpivot operation. Default is none.
#}

{% macro unpivot(table, cast_to='varchar', exclude=none) -%}

  {%- set exclude = exclude if exclude is not none else [] %}

  {%- set include_cols = [] %}

  {%- set table_columns = {} %}

  {%- set _ = table_columns.update({table: []}) %}

  {%- if table.name -%}
    {%- set schema, table_name = table.schema, table.name -%}
  {%- else -%}
    {%- set schema, table_name = (table | string).split(".") -%}
  {%- endif -%}

  {%- set cols = adapter.get_columns_in_table(schema, table_name) %}

  {%- for col in cols -%}
    {%- if col.column not in exclude -%}
      {% set _ = include_cols.append(col) %}
    {%- endif %}
  {%- endfor %}

  {%- for col in include_cols -%}

    select
      {%- for exclude_col in exclude %}
        {{ exclude_col }},
      {%- endfor %}
      {{dbt_utils.cast(col.column, 'varchar')}} as field_name,
      {{ dbt_utils.safe_cast(field=col.column, type=cast_to) }} as value
    from {{ table }}
    {% if not loop.last -%}
      union all
    {% endif -%}
  {%- endfor -%}
{%- endmacro %}
