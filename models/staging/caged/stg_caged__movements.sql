with source as (

    select * from {{ source('caged', 'microdados_movimentacao') }}

),

renamed as (

    select
        -- reference period
        ano                                as reference_year,
        mes                                as reference_month,

        -- location
        sigla_uf                           as state_code,
        id_municipio                       as municipality_id,

        -- economic sector
        cnae_2_secao                       as sector_section_code,
        cnae_2_subclasse                   as sector_code,

        -- occupation
        cbo_2002                           as occupation_code,

        -- worker profile
        categoria                          as worker_category,
        grau_instrucao                     as education_level,
        idade                              as age,
        raca_cor                           as race_color,
        sexo                               as gender,
        tipo_deficiencia                   as disability_type,
        indicador_aprendiz                 as is_apprentice,

        -- employment details
        horas_contratuais                  as contractual_hours,
        tipo_empregador                    as employer_type,
        tipo_estabelecimento               as establishment_type,
        tamanho_estabelecimento_janeiro    as establishment_size_january,
        indicador_trabalho_intermitente    as is_intermittent_work,
        indicador_trabalho_parcial         as is_part_time_work,

        -- movement info
        tipo_movimentacao                  as movement_type,
        saldo_movimentacao                 as movement_balance,
        salario_mensal                     as monthly_salary,

        -- metadata
        origem_informacao                  as information_source,
        indicador_fora_prazo               as is_late_submission

    from source

)

select * from renamed