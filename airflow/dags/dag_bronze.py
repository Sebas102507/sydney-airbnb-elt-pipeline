import logging
import os
import glob
from datetime import datetime
import pandas as pd
import re
from airflow.decorators import dag
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from sqlalchemy.engine import Engine

#########################################################
#
#   Load Environment Variables
#
#########################################################
AIRFLOW_DATA = "/home/airflow/gcs/data"

#########################################################
#
#   Helper Function & Custom Logic
#
#########################################################

def get_postgres_type(dtype):
    """Maps pandas dtype to a PostgreSQL data type."""
    if str(dtype) == 'int64':
        return "BIGINT"
    elif "int" in str(dtype):
        return "INTEGER"
    elif "float" in str(dtype):
        return "FLOAT"
    elif "datetime" in str(dtype):
        return "TIMESTAMP"
    elif "object" in str(dtype):
        return "VARCHAR"
    else:
        return "VARCHAR"

def extract_and_load_data_func(table_name: str, **kwargs):
    """
    Reads CSV data and loads it into a PostgreSQL table.
    - If 'merge' is used and the table doesn't exist, it creates it first.
    """
    file_to_load = kwargs.get('file_name')
    folder_to_load = kwargs.get('folder_name')
    strategy = kwargs.get('strategy', 'replace')
    unique_key = kwargs.get('unique_key')
    filter_by_filename_date = kwargs.get('filter_by_filename_date', False)
    df = None

    # --- Part 1: Read and Filter Data ---
    if file_to_load:
        file_path = os.path.join(AIRFLOW_DATA, file_to_load)
        if not os.path.exists(file_path):
            logging.error("File not found: %s. Skipping task.", file_path)
            return
        df = pd.read_csv(file_path, low_memory=False)
        
        if filter_by_filename_date:
            month_year_match = re.search(r'(\d{2})_(\d{4})\.csv$', file_to_load)
            if month_year_match:
                month, year = month_year_match.groups()
                filter_str = f"{year}-{month}"
                logging.info("Extracted year-month: %s. Will filter data.", filter_str)
                if 'SCRAPED_DATE' in df.columns:
                    df['SCRAPED_DATE'] = df['SCRAPED_DATE'].astype(str)
                    df = df[df['SCRAPED_DATE'].str.startswith(filter_str)]
    elif folder_to_load:
        pass
    else:
        logging.error("No file_name or folder_name provided. Skipping task.")
        return

    # --- Cleaning Logic ---
    df.dropna(axis=1, how='all', inplace=True)
    df = df.loc[:, ~df.columns.str.contains('^Unnamed')]

    # --- Part 2: Load Data to PostgreSQL ---
    pg_hook = PostgresHook(postgres_conn_id="postgres")
    engine = pg_hook.get_sqlalchemy_engine()
    target_schema, target_table_name = table_name.split('.')

    logging.info("--- Loading into %s with strategy: '%s' ---", table_name, strategy)

    if strategy == 'merge':
        check_table_sql = f"""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = '{target_schema}' 
            AND table_name = '{target_table_name}'
        );
        """
        table_exists = pg_hook.get_first(check_table_sql)[0]

        if not table_exists:
            logging.info("Table %s does not exist. Creating and inserting data.", table_name)
            
            cols_with_types = [f'"{col}" {get_postgres_type(dtype)}' for col, dtype in df.dtypes.items()]
            create_table_sql = f"CREATE TABLE {table_name} ({', '.join(cols_with_types)});"
            
            logging.info("Executing CREATE TABLE: %s", create_table_sql)
            pg_hook.run(create_table_sql)

            df.to_sql(name=target_table_name, con=engine, schema=target_schema, if_exists='append', index=False, chunksize=1000)
        else:
            logging.info("Table %s exists. Proceeding with merge.", table_name)
            if not unique_key:
                raise ValueError("A 'unique_key' is required for the merge strategy when the table exists.")
            
            if isinstance(unique_key, str):
                unique_key_list = [unique_key]
            else:
                unique_key_list = unique_key

            # NEW: Changed to a fixed temporary table name
            temp_table_name = f"temp_{target_table_name}"
            
            logging.info("Loading data into temporary table: %s", f"{target_schema}.{temp_table_name}")
            df.to_sql(name=temp_table_name, con=engine, schema=target_schema, if_exists='replace', index=False)

            conflict_keys = ", ".join([f'"{key}"' for key in unique_key_list])
            update_columns = [f'"{col}" = EXCLUDED."{col}"' for col in df.columns if col not in unique_key_list]
            
            if not update_columns:
                 merge_sql = f"""
                 INSERT INTO {table_name} ( {", ".join([f'"{col}"' for col in df.columns])} )
                 SELECT {", ".join([f'"{col}"' for col in df.columns])} FROM {target_schema}.{temp_table_name}
                 ON CONFLICT ({conflict_keys}) DO NOTHING;
                 """
            else:
                 merge_sql = f"""
                 INSERT INTO {table_name} ( {", ".join([f'"{col}"' for col in df.columns])} )
                 SELECT {", ".join([f'"{col}"' for col in df.columns])} FROM {target_schema}.{temp_table_name}
                 ON CONFLICT ({conflict_keys}) DO UPDATE
                 SET {", ".join(update_columns)};
                 """
            
            pg_hook.run(merge_sql)
            pg_hook.run(f"DROP TABLE {target_schema}.{temp_table_name};")

    else:
        df.to_sql(name=target_table_name, con=engine, schema=target_schema, if_exists=strategy, index=False, chunksize=1000)
    
    logging.info("Successfully loaded %d rows into %s.", len(df), table_name)


#########################################################
#
#   DAG Definition
#
#########################################################

default_args = {'owner': 'airflow', 'retries': 0}

@dag(
    dag_id='process_data_from_gcs_folders_to_db_bronze',
    start_date=datetime(2025, 10, 6),
    schedule=None,
    catchup=False,
    tags=['gcs', 'postgres', 'etl'],
    default_args=default_args
)
def gcs_to_postgres_bronze_dag():
    """
    ### GCS to Postgres Bronze Layer ETL
    This DAG extracts data from local GCS files, cleans it, and loads it
    into the 'bronze' schema in PostgreSQL.
    """
    load_census_g01_task = PythonOperator(
        task_id='load_census_g01_to_postgres',
        python_callable=extract_and_load_data_func,
        op_kwargs={
            'file_name': 'Census LGA/2016Census_G01_NSW_LGA.csv',
            'table_name': 'bronze.census_g01_nsw_lga_bronze',
            'strategy': 'replace'
        }
    )

    load_census_g02_task = PythonOperator(
        task_id='load_census_g02_to_postgres',
        python_callable=extract_and_load_data_func,
        op_kwargs={
            'file_name': 'Census LGA/2016Census_G02_NSW_LGA.csv',
            'table_name': 'bronze.census_g02_nsw_lga_bronze',
            'strategy': 'replace'
        }
    )

    load_listings_task = PythonOperator(
        task_id='load_listings_to_postgres',
        python_callable=extract_and_load_data_func,
        op_kwargs={
            'file_name': 'listings/05_2020.csv', ## Here you can change the file name to load the data into the database. so, every month you can change the file name to load the data into the database.
            'table_name': 'bronze.listings_bronze',
            'strategy': 'merge',
            'unique_key': ['LISTING_ID', 'SCRAPED_DATE'],
            'filter_by_filename_date': True
        }
    )

    load_nsw_lga_code_task = PythonOperator(
        task_id='load_nsw_lga_code_to_postgres',
        python_callable=extract_and_load_data_func,
        op_kwargs={
            'file_name': 'NSW_LGA/NSW_LGA_CODE.csv',
            'table_name': 'bronze.nsw_lga_code_bronze',
            'strategy': 'replace'
        }
    )

    load_nsw_lga_suburb_task = PythonOperator(
        task_id='load_nsw_lga_suburb_to_postgres',
        python_callable=extract_and_load_data_func,
        op_kwargs={
            'file_name': 'NSW_LGA/NSW_LGA_SUBURB.csv',
            'table_name': 'bronze.nsw_lga_suburb_bronze',
            'strategy': 'replace'
        }
    )

# Instantiate the DAG
gcs_to_postgres_bronze_dag()