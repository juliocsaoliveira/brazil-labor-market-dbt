with source as (

    select * from {{ source('bd_directories', 'municipio') }}

),

renamed as (

    select
        -- identifiers
        id_municipio                   as municipality_id,
        nome                           as municipality_name,

        -- state
        id_uf                         as state_id,
        sigla_uf                      as state_code,
        nome_uf                       as state_name,

        -- region hierarchy
        nome_regiao                   as region_name,
        nome_mesorregiao              as mesoregion_name,
        nome_microrregiao             as microregion_name,
        nome_regiao_imediata          as immediate_region_name,
        nome_regiao_intermediaria     as intermediate_region_name,
        nome_regiao_metropolitana     as metropolitan_region_name,

        -- attributes
        capital_uf                    as is_state_capital,
        amazonia_legal                as is_legal_amazon,
        ddd                           as area_code

    from source

)

select * from renamed