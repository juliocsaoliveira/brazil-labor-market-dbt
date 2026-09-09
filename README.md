# Brazil Labor Market Analytics (CAGED + dbt)

An end-to-end analytics engineering project that models Brazil's official labor market data — built to practice and showcase dbt + BigQuery skills.

## Overview

This project transforms raw monthly worker movement records (admissions and dismissals) from **CAGED** (Cadastro Geral de Empregados e Desempregados), Brazil's official labor registry maintained by the Ministry of Labor, into a clean, well-documented, analytics-ready dataset.

## Data source

- **Dataset:** CAGED microdata — monthly admission/dismissal records since 2020
- **Access:** [Base dos Dados](https://basedosdados.org) public dataset on Google BigQuery (`basedosdados.br_me_caged.microdados_movimentacao`)
- **Grain:** one row per worker movement (admission or dismissal)

## Architecture

- `staging/` — 1:1 with the source, renamed to English, typed, no business logic
- `intermediate/` — joins and business rules (as needed)
- `marts/core/` — dimensions and fact tables (star schema)
- `marts/labor_market/` — business-question-driven marts

All column names, model names, and documentation are in **English**, even though the raw source is in Portuguese — translation happens at the staging layer.

## Tech stack

- **Transformation:** dbt Core
- **Warehouse:** Google BigQuery
- **Version control:** GitHub
- **Documentation:** dbt docs

## How to run locally

1. Clone this repo.
2. Create a Python environment and install the BigQuery adapter:

   `pip install dbt-bigquery`

3. Authenticate with Google Cloud:

   `gcloud auth application-default login`

4. Configure your `profiles.yml` (see the [dbt docs](https://docs.getdbt.com/docs/configure-your-profile)) pointing to your own GCP project — the source data (`basedosdados`) is public, so you only need a project to run the transformations in.
5. Run the models:

   `dbt run`

   `dbt test`

## Author

Julio Oliveira — [LinkedIn](https://www.linkedin.com/in/julio-oliveira-prdct/) · [GitHub](https://github.com/juliocsaoliveira)