{{ config(
    materialized='view'
) }}

with movements as (

    select * from {{ ref('stg_caged__movements') }}
    where reference_year >= {{ var('fct_movements_start_year') }}

),

municipality as (

    select
        municipality_id,
        state_code,
        is_state_capital

    from {{ ref('stg_bd_directories__municipality') }}

),

worker_labels as (

    select
        movements.*,
        education_level.education_level,
        race_color.race_color,
        gender.gender,
        {{ age_bracket('movements.age') }} as age_bracket

    from movements
    left join {{ ref('education_level') }} as education_level
        on movements.education_level_code = education_level.grau_instrucao
    left join {{ ref('race_color') }} as race_color
        on movements.race_color_code = race_color.raca_cor
    left join {{ ref('gender') }} as gender
        on movements.gender_code = gender.sexo

),

occupation as (

    select distinct occupation_code
    from {{ ref('stg_bd_directories__occupation') }}

),

joined as (

    select
        worker_labels.* except (state_code),
        municipality.state_code,
        municipality.is_state_capital,
        coalesce(occupation.occupation_code, 'UNKNOWN') as valid_occupation_code

    from worker_labels
    left join municipality
        on worker_labels.municipality_id = municipality.municipality_id
    left join occupation
        on worker_labels.occupation_code = occupation.occupation_code

)

select
    -- surrogate keys (computed identically to their dimension tables, so they match on join)
    {{ dbt_utils.generate_surrogate_key(['reference_year', 'reference_month']) }} as time_key,
    {{ dbt_utils.generate_surrogate_key(['coalesce(state_code, \'UNKNOWN\')', 'coalesce(is_state_capital, 0)']) }} as location_key,
    {{ dbt_utils.generate_surrogate_key(['education_level', 'race_color', 'gender', 'age_bracket']) }} as worker_profile_key,
    valid_occupation_code as occupation_code,

    -- attributes kept at grain
    reference_year,
    reference_month,
    date(reference_year, reference_month, 1) as reference_date,    
    coalesce(state_code, 'UNKNOWN') as state_code,
    coalesce(is_state_capital, 0) as is_state_capital,
    sector_code,
    sector_section_code,
    worker_category,
    disability_type,
    is_apprentice,
    employer_type,
    establishment_type,
    establishment_size_january,
    is_intermittent_work,
    is_part_time_work,
    movement_type,
    information_source,
    is_late_submission,

    -- measures
    movement_balance,
    monthly_salary,
    contractual_hours

from joined