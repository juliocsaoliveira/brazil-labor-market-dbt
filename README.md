# Brazil Labor Market Analytics (CAGED + dbt)

An end-to-end analytics engineering project that models Brazil's official labor market data — built to practice and showcase dbt + BigQuery skills.

## Overview

This project transforms raw monthly worker movement records (admissions and dismissals) from **CAGED** (Cadastro Geral de Empregados e Desempregados), Brazil's official labor registry maintained by the Ministry of Labor, into a clean, tested, documented, analytics-ready star schema.

The project follows the layered modeling pattern common in production analytics engineering — staging, dimensional modeling, and business-facing marts — with an emphasis on documenting the reasoning behind each modeling decision, not just the SQL itself.

## Data sources

- **CAGED microdata** — monthly admission/dismissal records. [Base dos Dados](https://basedosdados.org) public dataset on Google BigQuery (`basedosdados.br_me_caged.microdados_movimentacao`).
- **Municipality and occupation reference tables** — also from Base dos Dados (`br_bd_diretorios_brasil.municipio`, `br_bd_diretorios_brasil.cbo_2002`), used to enrich the raw data with location and occupation hierarchy.
- **Grain of the core fact table:** one row per worker movement (admission or dismissal).

## Architecture

- `staging/` — 1:1 with the source, renamed to English, typed, no business logic.
- `marts/core/` — dimensions and the central fact table (star schema).
- `marts/labor_market/` — business-question-driven analytical marts, built on top of the fact table.

All column names, model names, and documentation are in **English**, even though the raw source is in Portuguese — translation happens at the staging layer, since the project targets international job applications.

### Pipeline flow

```
┌──────────────┐     ┌───────────────┐     ┌───────────────┐      ┌─────────────────┐
│ CAGED source │ --> │    staging    │ --> │  marts/core   │ -->  │ marts/labor_    │
│ (Base dos    │     │  1:1, renamed │     │  star schema  │      │ market          │
│  Dados /     │     │  to English,  │     │  dim_* + fct_*│      │ business-facing │
│  BigQuery)   │     │  typed only   │     │               │      │ analytical marts│
└──────────────┘     └───────────────┘     └───────────────┘      └─────────────────┘
```

### Star schema

```
                              dim_time
                                 │
               dim_location ──┐  │  ┌── dim_occupation
                              │  │  │
                              ▼  ▼  ▼
                          ┌───────────────┐
                          │ fct_movements │
                          │  (1 row per   │
                          │   movement)   │
                          └───────────────┘
                                 ▲
                                 │
                        dim_worker_profile
                    (education, race, gender,
                          age bracket)
```

| Table | Type | Grain |
|---|---|---|
| `fct_movements` | Fact | One row per worker movement (admission or dismissal) |
| `dim_time` | Dimension | One row per year-month |
| `dim_location` | Dimension | One row per state x capital/interior indicator |
| `dim_occupation` | Dimension | One row per CBO 2002 occupation code |
| `dim_worker_profile` | Mini-dimension | One row per distinct combination of education level, race/color, gender, and age bracket that occurs in the data |


## Key modeling decisions

This section exists because *why* a decision was made matters as much as the decision itself — this is the part meant to show analytical judgment, not just implementation.

**Mini-dimension for demographic attributes.** Instead of joining `education_level`, `race_color`, `gender`, and `age_bracket` separately onto the fact table, they're combined into a single `dim_worker_profile` with a surrogate key. This is the classic Kimball mini-dimension pattern: these four attributes have low combined cardinality, so pre-computing the distinct combinations that actually occur in the data keeps the fact table narrower and the joins simpler, at the cost of losing the ability to query each attribute in isolation without going through the mini-dimension — an acceptable trade-off here, since the project's analytical questions are aggregate by nature.

**Location collapsed to state + capital/interior, not municipality.** `dim_location` deliberately drops city-level granularity in favor of `state_code` plus a capital/interior boolean. Municipality-level detail wasn't needed for the intended analyses, and collapsing it keeps the dimension small (about 54 rows) while retaining a meaningful geographic signal — capital cities tend to have a different labor market dynamic than the interior of the same state.

**Surrogate keys where the natural key is composite, natural keys where it's already simple.** `dim_time` and `dim_location` use a hashed surrogate key (`dbt_utils.generate_surrogate_key`) because their natural keys are composite (year + month; state + capital indicator). `dim_occupation` uses `occupation_code` directly as its key, since it's already a single, stable, unique identifier — generating a hash there would add a transformation with no real benefit.

**Age brackets: under 18, then 5-year bands from 18-24 to 60-64, then 65+.** This mirrors how Brazilian labor market research commonly buckets ages — a wider first adult band (18-24) captures early-career/first-job dynamics as a group, while 5-year bands afterward better capture career progression. Implemented as a reusable macro (`macros/age_bracket.sql`) rather than repeated `CASE WHEN` logic.

**Code-to-label decoding happens in `marts`, via seeds — never in `staging`.** Categorical codes (education level, race/color, gender, economic sector section) are translated to labels using dbt seeds (static, versioned CSV lookup tables), joined in at the marts layer. Staging stays a strict 1:1 passthrough of the source, renamed and typed only; business-meaningful transformations, including decoding, belong downstream. Label values for education level, race/color, and gender were not guessed — they were validated against the real frequency distribution in the data (for example, confirming which numeric code corresponds to "Male" versus "Female" by checking which had a larger share, consistent with the known demographics of Brazil's formal labor market) before being encoded into the seeds.

**Explicit "not identified" handling instead of dropping rows.** Some CAGED records have a null municipality ID or an occupation code not covered by the reference directory (including a sentinel value CAGED itself uses for "not classified"). Rather than silently excluding these rows (which would understate total movements) or letting them produce orphaned foreign keys, both `dim_location` and `dim_occupation` include an explicit "unknown/not identified" row, and the fact table maps unmatched codes to it via `COALESCE`. Referential integrity is enforced with `relationships` tests between the fact table and every dimension.

**Fact table materialized as a view, not a partitioned/clustered table.** In a production environment with a BigQuery billing account attached, `fct_movements` would be a physical table partitioned by `reference_date` (monthly) and clustered by `state_code` — the standard pattern for a fact table this size, minimizing bytes scanned per query. This project runs on BigQuery Sandbox (no billing account, to keep the project at zero cost), which caps total storage at 10GB — not enough for the full CAGED history as a physical table. The fact table is scoped to recent years (configurable via a dbt variable) and materialized as a view instead, which consumes no storage quota at the cost of recomputing the query on every read. This is a conscious trade-off for a zero-cost portfolio environment, not an oversight — the partitioning/clustering approach is documented here for context on what the production version would look like.

**Salary outliers excluded using the official CAGED methodology.** Raw salary values include data-entry errors (values as absurd as a trillion reais). Rather than picking an arbitrary cutoff, the analytical mart excludes salaries below 0.3x or above 150x the national minimum wage of the reference year — the same rule the Ministry of Labor applies in its own official Novo CAGED bulletins. Minimum wage by year is stored in a small seed table.

## Tech stack

- **Transformation:** dbt Core
- **Warehouse:** Google BigQuery
- **Version control:** GitHub
- **Documentation:** dbt docs
- **Package:** dbt-labs/dbt_utils (surrogate key generation)

## How to run locally

1. Clone this repo.
2. Create a Python environment and install the BigQuery adapter:

   `pip install dbt-bigquery`

3. Authenticate with Google Cloud:

   `gcloud auth application-default login`

4. Configure your `profiles.yml` (see the [dbt docs](https://docs.getdbt.com/docs/configure-your-profile)) pointing to your own GCP project — the source data (basedosdados) is public, so you only need a project to run the transformations in.
5. Install dbt package dependencies:

   `dbt deps`

6. Load the seeds (label lookup tables):

   `dbt seed`

7. Run and test the models:

   `dbt run`

   `dbt test`

## Author

Julio Oliveira — [LinkedIn](https://www.linkedin.com/in/julio-oliveira-prdct/) - [GitHub](https://github.com/juliocsaoliveira)