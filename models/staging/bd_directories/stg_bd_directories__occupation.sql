with source as (

    select * from {{ source('bd_directories', 'cbo_2002') }}

),

renamed as (

    select
        -- identifier
        cbo_2002                           as occupation_code,
        descricao                          as occupation_name,

        -- hierarchy
        familia                            as family_code,
        descricao_familia                  as family_name,
        subgrupo                           as subgroup_code,
        descricao_subgrupo                 as subgroup_name,
        subgrupo_principal                 as main_subgroup_code,
        descricao_subgrupo_principal       as main_subgroup_name,
        grande_grupo                       as major_group_code,
        descricao_grande_grupo             as major_group_name,

        -- attribute
        indicador_cbo_2002_ativa           as is_active

    from source

)

select * from renamed