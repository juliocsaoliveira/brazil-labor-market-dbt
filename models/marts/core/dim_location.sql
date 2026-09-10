with municipalities as (

    select
        state_code,
        state_name,
        region_name,
        is_state_capital

    from {{ ref('stg_bd_directories__municipality') }}

),

distinct_locations as (

    select distinct
        state_code,
        state_name,
        region_name,
        is_state_capital

    from municipalities

    union all

    select
        'UNKNOWN' as state_code,
        'Not identified' as state_name,
        'Not identified' as region_name,
        0 as is_state_capital

)

select
    {{ dbt_utils.generate_surrogate_key(['state_code', 'is_state_capital']) }} as location_key,
    state_code,
    state_name,
    region_name,
    is_state_capital

from distinct_locations