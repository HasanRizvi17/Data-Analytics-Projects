### importing relevant libraries
from airflow import DAG 
''' This line imports the DAG class from the airflow library. The DAG class is used to define and create directed acyclic graphs (DAGs) in Apache Airflow. '''
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.utils.dates import datetime, timedelta
from airflow.operators.python import PythonOperator
'''
These lines import various operator classes from Airflow, which are used to define the individual tasks in the DAG. 
The operators imported include BashOperator, EmptyOperator, and PythonOperator. 
These operators allow you to run Bash commands, execute Python functions, and create placeholder tasks.
'''
import os
import sys
''' 
- The os and sys libraries in Python are both standard libraries that provide various functions and classes for interacting with the operating system, 
system-specific configurations, and the Python interpreter itself 
# os
The os library is used for performing various operations related to the operating system. 
It provides a way to interact with the file system, execute shell commands, and access environment variables. 
Some of the common functions and classes in the os library include:
- os.environ: This is a dictionary-like object that holds environment variables. You can access environment variables by name, like os.environ["VAR_NAME"].
# sys
The sys library provides functions and variables that interact with the Python interpreter and access system-specific configuration. 
Some of the commonly used functions and attributes in the sys library include:
- sys.path: A list of directory names where Python looks for modules to import. You can modify this list to include custom module paths.
'''


### loading relevant variables and paths/directories from the VM in Google Cloud Platform
sys.path.insert(0, '/home/data-team/data-engineering/airflow/modules_1')
'''
# how the code works
- This line inserts a custom directory path ('/home/data-team/data-engineering/airflow/modules') into the Python sys path. 
- In Python, sys.path is a list that contains directory paths where Python looks for modules to import. 
- It's essentially the list of directories that Python searches to find Python modules.
- The 0 is the index at which the specified path is being inserted into the sys.path list. 
- By using sys.path.insert(0, ...), the code is instructing Python to insert the specified directory path at the beginning of the sys.path list. 
# importance:
- It allows the DAG to import Python modules located in that directory. 
- This is useful for using custom Python functions and classes defined in those modules within the DAG.

'''
from mongo_batch_load_company import mongo_batch_load
'''
This line imports the mongo_batch_load function from a module named mongo_batch_load_company in the same directory in our VM on Google Cloud Platform. 
The function is used as the target for the PythonOperator task later in the code.
'''
DBT_DIR = os.environ["DBT_DIR"]
'''
This line retrieves the value of the DBT_DIR environment variable and assigns it to the DBT_DIR variable. 
This variable is used to specify the location/path of the DBT project directory (inside the GCP Virtual Machine (VM)) in the subsequent BashOperator tasks.
# Configurability and Reusability: 
- By using an environment variable like DBT_DIR, you can make the location of the DBT project directory configurable. 
- This is useful in scenarios where you might have multiple environments (e.g., development, staging, production) or different instances of the same DAG. 
- Each environment or instance can set a different DBT_DIR value to specify where the DBT project resides. 
- It makes your DAG more flexible and reusable across different setups.
# Ease of Deployment: 
- When deploying the DAG to different environments or when sharing it with others, the DBT_DIR configuration can be modified at the environment level without touching the DAG code. 
- This makes it easier to deploy the same DAG to various environments.
'''

### Building the DAG

default_args={
    'start_date': datetime(2023, 1, 20),
    'retries': 0,
    'retry_delay': timedelta(minutes=1),
    'email_on_failure': True,
    'catchup': False,
    'email': ['hasan.rizvi@company.com']
}
'''
# 'start_date':
This parameter specifies the start date and time for the DAG. It determines when the DAG should begin its execution schedule.
In the provided example, 'start_date' is set to datetime(2023, 1, 20), which means the DAG will start running on January 20, 2023.
The start date is a crucial parameter as it helps Airflow calculate when each task within the DAG should be executed based on the specified schedule.

# 'retries':
This parameter specifies the number of times a task should be retried in case it fails.
In the example, 'retries' is set to 0, which means that tasks will not be retried if they fail. This is effectively disabling task retries.

# 'retry_delay':
This parameter defines the amount of time to wait before each retry attempt if a task fails. It's specified as a timedelta object.
In the example, 'retry_delay' is set to timedelta(minutes=1), which means that a failed task will be retried after a 1-minute delay.

# 'email_on_failure':
This parameter is a boolean that determines whether or not email notifications should be sent when a task fails.
In the example, 'email_on_failure' is set to True, which means that email notifications will be sent in case of task failures.

# 'catchup':
This parameter is a boolean that controls whether or not the DAG should attempt to backfill or catch up on missed schedules. When set to True, the DAG will execute tasks for missed execution dates (for all intervals between the DAG start_date and today).
There are few use-cases for this parameter
In the example, 'catchup' is set to False, meaning the DAG will not backfill missed schedules.

# 'email':
This parameter is a list of email addresses to which email notifications will be sent in case of task failures.
'''

with DAG(
    dag_id = 'data_warehouse_pipeline',
    default_args=default_args,
    description='An Airflow DAG to invoke all changelogs extraction table',
    schedule='@daily',
    catchup=False
) as dag:
'''
This block creates a new DAG named 'company_data_warehouse_pipeline'. It uses the DAG class with the following parameters:
dag_id='company_data_warehouse_pipeline': The name of the DAG.
default_args=default_args: The default configuration settings defined earlier in the default_args dictionary.
description='An Airflow DAG to invoke all changelogs extraction table': A description of the DAG.
schedule='0 1,14 * * *': The schedule for running the DAG, which is set to run at 1:00 AM and 2:00 PM every day (UTC time).
catchup=False: The catchup parameter is set to False, meaning the DAG will not attempt to backfill or catch up on missed schedules.
as dag: The DAG object is assigned to the variable dag.
'''

    start = EmptyOperator(task_id='start')
    '''
    This line creates an empty task named start using the EmptyOperator. 
    It serves as the starting point of the DAG, with no actual work to perform. 
    It's used to initiate the task dependencies.
    '''

    mongo_batch_load_company = PythonOperator(
        task_id='mongo_batch_load_company', 
        python_callable=mongo_batch_load,
    )
    '''
    This line creates a PythonOperator task named mongo_batch_load_company. 
    This task is associated with the mongo_batch_load Python function. 
    When executed, it will run the mongo_batch_load function we imported from the mongo_batch_load_company module.
    '''

    mongodb_changelog_data_capture = BashOperator(
        task_id='mongodb_changelog_data_capture',
        bash_command=f'cd {DBT_DIR} && dbt run --model company_mongodb_changelog_data'
    )
    '''
    This line creates a BashOperator task named mongodb_changelog_data_capture. 
    It will run a Bash command that changes the working directory to DBT_DIR and executes a DBT command to capture data changes from MongoDB.
    '''

    mongodb_changelog_extraction = BashOperator(
        task_id='mongodb_changelog_extraction',
        bash_command=f'cd {DBT_DIR} && dbt run --select company_changelog_extracted_data'
    )
    '''Same as mongodb_changelog_data_capture'''

    mongodb_latest_data_layer_creation = BashOperator(
        task_id='mongodb_latest_data_layer_creation',
        bash_command=f'cd {DBT_DIR} && dbt run --select company_latest_data'
    )
    '''Same as mongodb_changelog_data_capture'''

    end = EmptyOperator(task_id='end')
    '''
    This line creates an empty task named end using the EmptyOperator. 
    It serves as the endpoint of the DAG, with no actual work to perform. 
    It's used to finish the chain of task dependencies.
    '''

    start >> mongo_batch_load_company >> mongodb_changelog_data_capture >> mongodb_changelog_extraction >> mongodb_latest_data_layer_creation >> end
    '''Defining the sequence of tasks in the DAG in a chain'''