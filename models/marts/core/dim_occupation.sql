with occupations as (

    select
        occupation_code,
        occupation_name,
        family_code,
        family_name,
        subgroup_code,
        subgroup_name,
        main_subgroup_code,
        main_subgroup_name,
        major_group_code,
        major_group_name,
        is_active

    from {{ ref('stg_bd_directories__occupation') }}

    union all

    select
        'UNKNOWN' as occupation_code,
        'Not identified' as occupation_name,
        'UNKNOWN' as family_code,
        'Not identified' as family_name,
        'UNKNOWN' as subgroup_code,
        'Not identified' as subgroup_name,
        'UNKNOWN' as main_subgroup_code,
        'Not identified' as main_subgroup_name,
        'UNKNOWN' as major_group_code,
        'Not identified' as major_group_name,
        0 as is_active

)

select * from occupations