import psycopg2
import time


def check_pgsql(*args, **kwargs):
    while True:
        try:
            conn = psycopg2.connect(dbname='template1', host="server",
                                    user='postgres', password='postgres')
            cur = conn.cursor()
            cur.execute("select pg_postmaster_start_time()")
            return True
        except:
            time.sleep(.5)  # give it a chance to start
