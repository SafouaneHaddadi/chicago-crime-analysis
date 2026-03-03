import pyodbc
import pandas as pd

def load_dashboard_data(view_name='vw_ExecutiveDashboard'):
    """
    This function connects to our SQL Server and returns the data from our view
    """
    server = 'IverSaf\\SQLDEV2025'          
    database = 'ChicagoProject'             
    driver = '{ODBC Driver 18 for SQL Server}'  

    conn_str = (
        f'DRIVER={driver};'
        f'SERVER={server};'
        f'DATABASE={database};'
        f'Trusted_Connection=yes;'      
        'Encrypt=no;'                   
    )

    try:
        conn = pyodbc.connect(conn_str)
        
        query = f"SELECT * FROM {view_name}"
        df = pd.read_sql(query, conn)
        
        conn.close()
        
        return df 
        
    except Exception as e:
        print("Connection error:", str(e))
        return None   