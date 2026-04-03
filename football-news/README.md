# FootNews — Agrégateur d'actualités football

Lecteur de flux RSS pour la presse football européenne avec scoring de fiabilité et détection du putaclick.

## Fonctionnalités

- **Agrégation RSS** : journaux (L'Équipe, Marca, Gazzetta…), sites et flux Twitter via Nitter
- **Score de fiabilité** (1–5) : combinaison de la réputation de la source et d'un score anti-clickbait
- **Détection automatique du putaclick** : sources vagues, urgence artificielle, superlatifs, majuscules excessives…
- **Tags par source** : affiliation club, ville, type de source (journal madrilène pro-Real, journaliste parisien…)
- **Filtres** : par pays, type de source, score minimum, seuil clickbait, recherche plein texte
- **Panel de gestion des sources** : activer/désactiver chaque source
- **Rafraîchissement automatique** toutes les 15 minutes

## Lancement rapide

### Sans Docker

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
# Ouvrir http://localhost:8000
```

### Avec Docker Compose

```bash
docker-compose up --build
# Ouvrir http://localhost:8000
```

## Sources préconfigurées

| Source | Pays | Type | Fiabilité | Affiliation |
|---|---|---|---|---|
| L'Équipe | 🇫🇷 | Journal | ★★★★ | — |
| Le Parisien | 🇫🇷 | Journal | ★★★ | PSG |
| Marca | 🇪🇸 | Journal | ★★★ | Real Madrid |
| AS | 🇪🇸 | Journal | ★★★ | Real Madrid |
| Sport | 🇪🇸 | Journal | ★★ | FC Barcelone |
| Mundo Deportivo | 🇪🇸 | Journal | ★★ | FC Barcelone |
| La Gazzetta | 🇮🇹 | Journal | ★★★★ | — |
| Corriere dello Sport | 🇮🇹 | Journal | ★★★ | — |
| Tuttosport | 🇮🇹 | Journal | ★★ | Juventus |
| Kicker | 🇩🇪 | Journal | ★★★★ | — |
| Bild | 🇩🇪 | Journal | ★★ | tabloïd |
| The Guardian | 🏴󠁧󠁢󠁥󠁮󠁧󠁿 | Journal | ★★★★★ | — |
| BBC Sport | 🏴󠁧󠁢󠁥󠁮󠁧󠁿 | Journal | ★★★★★ | — |
| Sky Sports | 🏴󠁧󠁢󠁥󠁮󠁧󠁿 | Journal | ★★★ | — |
| Fabrizio Romano | 🇮🇹 | Journaliste | ★★★★★ | Mercato |
| David Ornstein | 🏴󠁧󠁢󠁥󠁮󠁧󠁿 | Journaliste | ★★★★★ | Mercato |
| Matteo Moretto | 🇮🇹 | Journaliste | ★★★★ | Mercato |
| Romain Molina | 🇫🇷 | Journaliste | ★★★★ | Investigation |
| Ekrem Konur | 🇹🇷 | Journaliste | ★★ | — |
| Le10Sport | 🇫🇷 | Site web | ★★ | putaclick |
| Foot Mercato | 🇫🇷 | Site web | ★★ | Mercato |

## Score de fiabilité

Le score final (1–5) est calculé ainsi :

```
score_final = score_source − (score_clickbait × 2)
```

**Détection clickbait** pénalise :
- Sources vagues ("selon nos informations", "un grand club")
- Urgence artificielle ("BREAKING", "EXCLU", "IMMINENT")
- Superlatifs sensationnels
- Titres conditionnels spéculatifs
- Ponctuation excessive (!!!, ???)
- MAJUSCULES excessives

## API

```
GET  /api/articles       ?page, per_page, sort, search, country, min_score, max_clickbait, tag, source_id
GET  /api/sources
PATCH /api/sources/{id}  { enabled, reliability, tags, affiliation }
POST /api/refresh        Lance un rafraîchissement global
POST /api/refresh/{id}   Rafraîchit une source spécifique
GET  /api/stats
```

## Ajouter une source

Éditer `backend/data/sources.json` ou faire un PATCH sur l'API.

```json
{
  "id": "mon_journal",
  "name": "Mon Journal",
  "url": "https://monjournal.com/rss/football.xml",
  "type": "newspaper",
  "country": "FR",
  "language": "fr",
  "city": "Lyon",
  "reliability": 3,
  "tags": ["France", "Lyon"],
  "affiliation": null,
  "twitter_handle": null
}
```

Pour un journaliste Twitter, renseigner `twitter_handle` (flux via Nitter) :

```json
{
  "id": "mon_journaliste",
  "name": "Prénom Nom",
  "url": "https://nitter.net/MonHandle/rss",
  "type": "journalist",
  "twitter_handle": "MonHandle",
  ...
}
```
