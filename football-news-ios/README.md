# FootNews iOS — Agrégateur football pour iPhone

Application SwiftUI native iPhone 16 (iOS 17+), sans backend, qui agrège directement les flux RSS des médias football européens.

## Fonctionnalités

- Lecture RSS/Atom native (pas de dépendance externe)
- Score de fiabilité (1–5) par article
- Détection automatique du clickbait avec flags explicatifs
- Tags par source : affiliation club, ville, type
- Filtres : pays, type, score min, anti-putaclick, recherche texte
- Lecture des articles dans SFSafariViewController (Reader mode)
- Onglet Statistiques : distribution fiabilité, flux les plus actifs
- Gestion des sources : activer/désactiver, swipe pour actualiser
- Dark mode natif, Dynamic Island-aware
- Cache local (UserDefaults) pour lecture hors connexion
- Pull-to-refresh + rafraîchissement manuel

## Mise en place dans Xcode

1. **Ouvrir Xcode** → File → New → App
   - Product Name: `FootNews`
   - Team: ton équipe / compte personnel
   - Bundle ID: `com.yourname.footnews`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - iOS Deployment Target: **17.0**

2. **Supprimer** le fichier `ContentView.swift` généré par défaut

3. **Ajouter les fichiers Swift** du dossier `FootNews/` en les glissant dans le projet Xcode
   (cocher "Copy items if needed")

4. **Build & Run** sur simulateur iPhone 16 ou appareil physique

> Aucune CocoaPod, aucun SPM package requis — 100% frameworks Apple.

## Architecture

```
FootNews/
├── FootNewsApp.swift               # @main entry point
├── Models/
│   ├── Source.swift                # Source + 21 sources préconfigurées
│   └── Article.swift               # Article + helpers couleur/label
├── Services/
│   ├── ClickbaitDetector.swift     # Scoring clickbait (NSRegularExpression)
│   ├── RSSParser.swift             # XMLParser RSS 2.0 + Atom 1.0
│   └── FeedManager.swift           # ViewModel principal (@MainActor)
└── Views/
    ├── ContentView.swift           # TabView (Fil / Stats / Sources)
    ├── Feed/
    │   ├── FeedView.swift          # Liste articles + tag bar + toolbar
    │   ├── ArticleCardView.swift   # Card native avec score + flags
    │   └── ArticleDetailView.swift # SFSafariViewController wrapper
    ├── Sources/
    │   └── SourcesView.swift       # Gestion sources + swipe actions
    └── Components/
        ├── ScoreBadge.swift        # ScoreBadge, TagChip, ClickbaitFlag
        └── FilterSheet.swift       # Sheet filtres + FlowLayout tags
```

## Score de fiabilité

```
score_final = score_source (1–5) − (score_clickbait × 2)
```

| Score | Label |
|---|---|
| ≥ 4.5 | Très fiable |
| ≥ 3.5 | Fiable |
| ≥ 2.5 | À vérifier |
| ≥ 1.5 | Peu fiable |
| < 1.5 | Putaclick |

## Ajouter une source

Dans `Models/Source.swift`, ajouter une entrée dans `Source.allSources` :

```swift
Source(id: "mon_journal",
       name: "Mon Journal",
       feedURL: "https://monjournal.com/rss/football.xml",
       type: .newspaper,
       country: "FR", language: "fr", city: "Lyon",
       reliability: 3,
       tags: ["France", "Lyon"],
       affiliation: nil, twitterHandle: nil, isEnabled: true),
```

Pour un journaliste Twitter (via Nitter) :

```swift
Source(id: "mon_journaliste",
       name: "Prénom Nom",
       feedURL: "https://nitter.poast.org/MonHandle/rss",
       type: .journalist,
       country: "FR", language: "fr", city: "Paris",
       reliability: 4,
       tags: ["Mercato"],
       affiliation: nil, twitterHandle: "MonHandle", isEnabled: true),
```
