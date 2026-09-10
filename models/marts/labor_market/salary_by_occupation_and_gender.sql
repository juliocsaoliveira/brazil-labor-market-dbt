-- models/marts/labor_market/salary_by_occupation_and_gender.sql
with movements as (

    select * from {{ ref('fct_movements') }}
    where movement_balance = 1

),

with_labels as (

    select
        movements.reference_year,
        occupation.occupation_name,
        occupation.major_group_name as occupation_group,
        worker_profile.gender,
        movements.monthly_salary

    from movements
    left join {{ ref('dim_occupation') }} as occupation
        on movements.occupation_code = occupation.occupation_code
    left join {{ ref('dim_worker_profile') }} as worker_profile
        on movements.worker_profile_key = worker_profile.worker_profile_key
    left join {{ ref('minimum_wage') }} as minimum_wage
        on movements.reference_year = minimum_wage.reference_year

    where movements.monthly_salary between (0.3 * minimum_wage.minimum_wage) and (150 * minimum_wage.minimum_wage)

)

select
    reference_year,
    occupation_name,
    occupation_group,
    gender,
    count(*) as admission_count,
    round(avg(monthly_salary), 2) as average_salary,
    round(approx_quantiles(monthly_salary, 2)[offset(1)], 2) as median_salary

from with_labels
group by reference_year, occupation_name, occupation_group, gender