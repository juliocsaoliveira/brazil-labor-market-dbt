with movements as (

    select distinct
        reference_year,
        reference_month

    from {{ ref('stg_caged__movements') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['reference_year', 'reference_month']) }} as time_key,
    reference_year,
    reference_month,
    date(reference_year, reference_month, 1) as reference_date

from movements