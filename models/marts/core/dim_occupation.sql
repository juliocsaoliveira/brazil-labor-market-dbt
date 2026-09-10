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