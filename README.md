# Retail-Orders-Python-SQL-Project
The main objectives of this project are to use the Kaggle API to retrieve retail order data, execute pandas data transformation in Python, and use SQL Server for data analysis.
**[Ref: Ankit Bansal YT Channel](https://www.youtube.com/watch?v=uL0-6kfiH3g)**

## Project Overview
  The project performs the following steps:
  - **Extraction:** Extracts data from Kaggle using the Kaggle API (Python).
  - **Transformation:** Cleans and transforms the data for analysis using pandas (Python).
  - **Loading:** Loads the transformed data into a SQL Server database.
  - **Insights:** Carries out analysis on the retail order data using SQL Server to find patterns.

## Technologies Used
  - Python
  - Pandas
  - Kaggle API
  - SQL Server

## Extract
  **Kaggle API for data downlaod**
  - Open Kaggle website and go to settings option then click on 'Create New Token'.
  - Download the kaggle.json file.
  - Now, go to your home directory in your PC like 'C:\Users\suman\.kaggle', if '.kaggle' folder is not there then create a new one and paste the 'kaggle.json' file right there.

## Transform
  **Python for Data Cleaning**
  - I’m using VS Code to use jupyter notebook.
  - Open the VS Code and create a new '.ipynb' file in a local folder, where we can write python codes.
    ```python
    # install libraries
    !pip install kaggle
    ```
    ```python
    # import libraries
    import kaggle
    ```
    ```python
    # downloading the dataset using kaggle api
    # copy the api command from kaggle dataset only
    !kaggle datasets download -d ankitbansal06/retail-orders
    ```
    ```python
    # this is an zip file, so extract files from zip file
    import zipfile # importing zipfile libraries
    openfile = zipfile.ZipFile('retail-orders.zip') # open the file
    openfile.extractall() # extract files to the directory
    openfile.close() # close the file
    ```
    ```python
    # read the the file in pandas
    import pandas as pd # importing pandas libraries
    df = pd.read_csv('D:\\Books\\Python\\Project\\Retail-Orders-Python-SQL-Project\\orders.csv')
    ```
    ```python
    # reading few values
    df.head(10)
    ```
    ```python
    # some null values are there in 'Ship Mode' column so, we need to fix this
    df['Ship Mode'].unique()
    ```
    ```python
    # reading the dataset again and use defaut option to change 'Not Available' & 'unknown' values to NaN
    df = pd.read_csv('D:\\Books\\Python\\Project\\Retail-Orders-Python-SQL-Project\\orders.csv', na_values=['Not Available', 'unknown'])
    df['Ship Mode'].unique()
    ```
    ```python
    # now fix the column names as it has space and non uniformatity in names
    df.columns
    ```
    ```python
    # lowercase the column names
    df.columns = df.columns.str.lower()
    df.columns
    ```
    ```python
    # add _ inplace of ' '
    df.columns = df.columns.str.replace(' ', '_')
    df.columns
    ```
    ```python
    # derive new column
    df['discount'] = (df.list_price * df.discount_percent) / 100 # actual discount column in amount
    df['sale_price'] = df.list_price - df.discount # sale_price is (list price - discount)
    df['profit'] = (df.sale_price - df.cost_price) # profit is (sale price - cost price)
    df
    ```
    ```python
    # now we can drop the extra columns
    df.drop(['cost_price', 'list_price', 'discount_percent'], axis=1, inplace=True)
    df
    ```
    ```python
    # now check the daatatypes of the columns
    df.dtypes
    ```
    ```python
    # look everythis is fine other than the 'order_date' column, 'order_date' column datatype needs to change to time datatype
    df.order_date = pd.to_datetime(df.order_date)
    df.dtypes
    ```

## Load
  **load to SQL Server using python**
  - now we cleaned the dataset and data is ready to load to SQL Server
    ```python
    # install libraries
    !pip install sqlalchemy
    ```
    ```python
    # connect to the sql server
    import pandas as pd
    import sqlalchemy as sal
    engine = sal.create_engine('mssql://sumanpc/master?driver=ODBC+DRIVER+17+FOR+SQL+SERVER')
    conn = engine.connect()
    ```
    ```python
    # now, load the data into sql server

    # df.to_sql('df_orders', con = conn, index=False, if_exists = 'replace')
    # we do not use 'replace' mode because it will create a table in sql with highest datatype values and it will take more space in memory

    # so, we will use 'append' mode, but first create a new empty table in SQL Server with all the column names and required datatype with values
    df.to_sql('df_orders', con = conn, index=False, if_exists = 'append')

    # DDL command from SSMS 
    # create table df_orders (
    #   [order_id] int primary key,
    #   [order_date] date,
    #   [ship_mode] varchar (20),
    #   [segment] varchar (20),
    #   [country] varchar (20),
    #   [city] varchar (20),
    #   [state] varchar (20),
    #   [postal_code] varchar (20),
    #   [region] varchar (20),
    #   [category] varchar (20),
    #   [sub_category] varchar (20),
    #   [product_id] varchar (50),
    #   [quantity] int,
    #   [discount] decimal (7,2),
    #   [sale_price] decimal (7,2),
    #   [profit] decimal (7,2))
    ```
## Analysis using SQL Server
  - Find top 10 highest reveue generating products
    ```sql
    select top 10 with ties product_id, sum(profit) total_profit from df_orders
    group by product_id
    order by 2 desc
    ```
    ![image](https://github.com/user-attachments/assets/f7c67686-f251-4dd8-919d-32143126dd69)
  - Find top 5 highest selling products in each region
    ```sql
    with cte as
    (select region, product_id, sum(sale_price) qty_sale,
    dense_rank() over(partition by region order by sum(sale_price) desc) rn
    from df_orders
    group by region, product_id)
    select * from cte where rn <= 5
    ```
    ![image](https://github.com/user-attachments/assets/7518681c-5a4f-4251-8c88-897cb2bbef2f)
  - Find month over month growth comparison for 2022 and 2023 sales eg jan 2022 vs jan 2023
    ```sql
    with cte as
    (select year(order_date) order_year, month(order_date) order_month, sum(sale_price) total_sale from df_orders
    group by year(order_date), month(order_date))
    select order_month,
    sum(case when order_year = 2022 then total_sale else 0 end) as sale_2022,
    sum(case when order_year = 2023 then total_sale else 0 end) as sale_2023,
    cast(cast(round(((sum(case when order_year = 2023 then total_sale else 0 end)) - (sum(case when order_year = 2022 then total_sale else 0 end))) * 100.0 / (sum(case when order_year = 2022 then total_sale else 0 end)), 2) as float) as varchar) + '%' as inc_or_dec_in_2023
    from cte
    group by order_month
    order by order_month
    ```
    ![image](https://github.com/user-attachments/assets/abbf9b68-55fa-4207-a621-dafb46dcb27f)

  - For each category which month had highest sales
    ```sql
    with cte as
    (select category, format(order_date, 'MMM-yyyy') mnth_yr, sum(sale_price) total_sale,
    dense_rank() over(partition by category order by sum(sale_price) desc) rn
    from df_orders
    group by category, format(order_date, 'MMM-yyyy'))
    select category, mnth_yr, total_sale
    from cte
    where rn = 1
    ```
    ![image](https://github.com/user-attachments/assets/08c55023-2f34-4fef-aee9-3a81a4289781)

  - Which sub category had highest growth by profit in 2023 compare to 2022?
    ```sql
    with cte as
    (select sub_category, year(order_date) order_year, sum(profit) total_profit from df_orders
    group by sub_category, year(order_date)),
    cte2 as
    (select sub_category,
    sum(case when order_year = 2022 then total_profit else 0 end) as profit_2022,
    sum(case when order_year = 2023 then total_profit else 0 end) as profit_2023
    from cte
    group by sub_category)
    select top 1 with ties *,
    (profit_2023 - profit_2022) * 100.0 / profit_2022 profit_percentage
    from cte2
    order by 4 desc
    ```
    ![image](https://github.com/user-attachments/assets/39dd3072-b053-4d94-b971-1e797fa1df33)

## Conclusion
  The Retail Orders Analysis project demonstrated how to use SQL and Python to get valuable insights out of retail data. We were able to determine the best-performing goods, local sales trends, and growth patterns from year to year by preprocessing and analyzing the data. These observations can help guide strategic decision-making and propel retail industry success.
