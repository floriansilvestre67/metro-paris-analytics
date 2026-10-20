import os
import time
import psycopg2
from dotenv import load_dotenv

# Charge les variables du fichier .env (mot de passe, etc.)
load_dotenv()

chemin_csv = "data/metro_paris_2020_2025.csv"

# Connexion à PostgreSQL : on passe par localhost car le script tourne sur ton PC
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    dbname=os.environ["POSTGRES_DB"],
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"],
)

debut = time.perf_counter()

with conn.cursor() as cur, open(chemin_csv, encoding="utf-8") as f:
    cur.execute("TRUNCATE staging.validations_brutes")
    cur.copy_expert(
        "COPY staging.validations_brutes (time, badge, station, type) "
        "FROM STDIN WITH (FORMAT csv, HEADER true)",
        f,
    )
conn.commit()

duree = time.perf_counter() - debut
print(f"Chargement terminé en {duree:.0f} secondes")

conn.close()