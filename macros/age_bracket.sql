{% macro age_bracket(age_column) %}
    case
        when {{ age_column }} < 18 then '<18'
        when {{ age_column }} between 18 and 24 then '18-24'
        when {{ age_column }} between 25 and 29 then '25-29'
        when {{ age_column }} between 30 and 34 then '30-34'
        when {{ age_column }} between 35 and 39 then '35-39'
        when {{ age_column }} between 40 and 44 then '40-44'
        when {{ age_column }} between 45 and 49 then '45-49'
        when {{ age_column }} between 50 and 54 then '50-54'
        when {{ age_column }} between 55 and 59 then '55-59'
        when {{ age_column }} between 60 and 64 then '60-64'
        when {{ age_column }} >= 65 then '65+'
        else 'Unknown'
    end
{% endmacro %}