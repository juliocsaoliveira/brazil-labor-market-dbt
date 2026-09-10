with movements as (

    select * from {{ ref('fct_movements') }}

),

with_labels as (

    select
        movements.reference_year,
        movements.state_code,
        movements.is_state_capital,
        sector_section.sector_section,
        occupation.occupation_name,
        case
            when movements.movement_balance = 1 then 'Admission'
            when movements.movement_balance = -1 then 'Dismissal'
            else 'Unknown'
        end as movement_direction,
        movements.monthly_salary

    from movements
    left join {{ ref('sector_section') }} as sector_section
        on movements.sector_section_code = sector_section.cnae_2_secao
    left join {{ ref('dim_occupation') }} as occupation
        on movements.occupation_code = occupation.occupation_code
    left join {{ ref('minimum_wage') }} as minimum_wage
        on movements.reference_year = minimum_wage.reference_year

    -- exclude salary outliers, following the same methodology used in official
    -- Novo CAGED bulletins: below 0.3x or above 150x the minimum wage of the year
    where movements.monthly_salary between (0.3 * minimum_wage.minimum_wage) and (150 * minimum_wage.minimum_wage)

)

select
    reference_year,
    state_code,
    is_state_capital,
    sector_section,
    occupation_name,
    movement_direction,
    count(*) as movement_count,
    round(avg(monthly_salary), 2) as average_salary,
    round(approx_quantiles(monthly_salary, 2)[offset(1)], 2) as median_salary

from with_labels
group by reference_year, state_code, is_state_capital, sector_section, occupation_name, movement_direction