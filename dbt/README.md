# airbnb_project (dbt)

Silver and Gold transformations for the Sydney Airbnb pipeline. See the [repository README](../README.md) for the full picture.

- `models/silver/clean/`: incremental staging of listings, hosts and properties; reference tables for LGAs, suburbs and Census data.
- `snapshots/silver/`: Type 2 slowly changing dimensions for hosts and properties.
- `models/gold/`: dimensions, the `fact_listing` fact table, Census reference tables and the three data-mart views.
- `macros/get_unique_versions.sql`: keeps one row per real change by hashing tracked columns.

```bash
dbt snapshot
dbt run
dbt test
```
