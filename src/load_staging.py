import os
import time
import psycopg2
from dotenv import load_dotenv

# Charge les variables du fichier .env (mot de passe, etc.)
load_dotenv()

chemin_data_validation = "data/metro_paris_2020_2025.csv"
chemin_data_stations = "data/metro-france.csv"
chemin_data_correspondance = "data/correspondances.csv"
chemin_data_communes = "data/communes_retenues.csv"
chemin_data_jours_feries = "data/jours_feries_metropole.csv"
chemin_data_vacances = "data/jours_vacances.csv"

# Connexion à PostgreSQL : on passe par localhost car le script tourne sur ton PC
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    dbname=os.environ["POSTGRES_DB"],
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"],
)

def charger_csv(conn, table, colonnes, chemin, separateur=","):
    """Vide la table puis la remplit avec le contenu du fichier CSV."""
    debut = time.perf_counter()
    liste_colonnes = ", ".join(colonnes)

    with conn.cursor() as cur, open(chemin, encoding="utf-8") as f:
        cur.execute(f"TRUNCATE {table}")
        cur.copy_expert(
            f"COPY {table} ({liste_colonnes}) "
            f"FROM STDIN WITH (FORMAT csv, HEADER true, DELIMITER '{separateur}')",
            f,
        )
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        nb_lignes = cur.fetchone()[0]

    conn.commit()

    duree = time.perf_counter() - debut
    print(f"{table} : {nb_lignes} lignes chargées en {duree:.0f} secondes")


nom_colonne_valid_brut = ["time", "badge", "station", "type"]
nom_colonne_stations_ref = ["id_line",'libelle_line', 'libelle_station', 'longitude', 'latitude',
                        'finish', 'commune_nom', 'commune_code_insee']
nom_colonne_correspo_noms = ["nom_validations","nom_referentiel","commentaire"]
nom_colonne_communes_retenues = ["commune_code_insee","commune_nom","commentaire"]
nom_colonnes_jours_feries = ['date','annee','zone,nom_jour_ferie']
nom_colonnes_vacances = ['date','vacances_zone_a','vacances_zone_b','vacances_zone_c','nom_vacances']
#charger_csv(conn,"staging.validations_brutes", nom_colonne_valid_brut,chemin_csv)
#charger_csv(conn, "staging.stations_referentiel",nom_colonne_stations_ref,chemin_data_stations)
#charger_csv(conn,"staging.correspondance_noms", nom_colonne_correspo_noms,chemin_data_correspondance)
#charger_csv(conn,"staging.communes_retenues", nom_colonne_communes_retenues,chemin_data_communes)
charger_csv(conn,"staging.vacances_scolaires", nom_colonnes_vacances,chemin_data_vacances)
charger_csv(conn,"staging.jours_feries", nom_colonnes_jours_feries,chemin_data_jours_feries)

conn.close()