with movements as (

    select distinct
        education_level_code,
        race_color_code,
        gender_code,
        {{ age_bracket('age') }} as age_bracket

    from {{ ref('stg_caged__movements') }}

),

with_labels as (

    select
        movements.age_bracket,
        education_level.education_level,
        race_color.race_color,
        gender.gender

    from movements
    left join {{ ref('education_level') }} as education_level
        on movements.education_level_code = cast(education_level.grau_instrucao as string)
    left join {{ ref('race_color') }} as race_color
        on movements.race_color_code = cast(race_color.raca_cor as string)
    left join {{ ref('gender') }} as gender
        on movements.gender_code = cast(gender.sexo as string)

)

select
    {{ dbt_utils.generate_surrogate_key(['education_level', 'race_color', 'gender', 'age_bracket']) }} as worker_profile_key,
    education_level,
    race_color,
    gender,
    age_bracket
from with_labels