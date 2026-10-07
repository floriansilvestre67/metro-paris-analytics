# Analyse des validations du métro parisien

Projet SAE (ISIMA) : pipeline ETL, base de données et analyse de 4 Go de validations de badges (entrées / sorties par station).

## Stack

- **Exploration** : Jupyter, pandas, DuckDB
- **Base de données** : PostgreSQL 16
- **Environnement** : Docker / Docker Compose

## Structure

```
.
├── data/          # données brutes (non versionnées)
├── notebooks/     # exploration et analyses
├── src/           # scripts ETL réutilisables
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```

## Lancer le projet

1. Placer le fichier de données dans `data/`
2. Créer le fichier d'environnement : `cp .env.example .env` (puis changer le mot de passe)
3. Démarrer : `docker compose up --build`
4. Ouvrir Jupyter : http://localhost:8888

Depuis un notebook, connexion à PostgreSQL :

```python
import os
from sqlalchemy import create_engine
engine = create_engine(os.environ["DATABASE_URL"])
```

## Avancement

- [ ] Exploration et qualité des données
- [ ] Modélisation et chargement PostgreSQL
- [ ] Reconstitution des trajets (entrée → sortie)
- [ ] Analyses (fraude, trajets fréquents, prévisions 2026)
- [ ] API REST et dashboards
