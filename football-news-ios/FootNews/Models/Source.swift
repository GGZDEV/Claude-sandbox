import Foundation

// MARK: - Enums

enum SourceType: String, Codable, CaseIterable {
    case newspaper = "newspaper"
    case journalist = "journalist"
    case website = "website"

    var label: String {
        switch self {
        case .newspaper:  return "Journal"
        case .journalist: return "Journaliste"
        case .website:    return "Site web"
        }
    }

    var color: String {
        switch self {
        case .newspaper:  return "indigo"
        case .journalist: return "sky"
        case .website:    return "violet"
        }
    }
}

// MARK: - Source Model

struct Source: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let feedURL: String
    let type: SourceType
    let country: String      // ISO 3166-1 alpha-2
    let language: String
    let city: String?
    var reliability: Int     // 1–5
    let tags: [String]
    let affiliation: String?
    let twitterHandle: String?
    var isEnabled: Bool

    var flag: String {
        let base: UInt32 = 127397
        return country.unicodeScalars.compactMap {
            Unicode.Scalar(base + $0.value).map { String($0) }
        }.joined()
    }
}

// MARK: - Pre-configured sources

extension Source {
    static let allSources: [Source] = [
        // ── France ──────────────────────────────────────────
        Source(id: "lequipe",
               name: "L'Équipe",
               feedURL: "https://www.lequipe.fr/rss/actu_rss_Football.xml",
               type: .newspaper, country: "FR", language: "fr", city: "Paris",
               reliability: 4, tags: ["France", "Généraliste"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        Source(id: "leparisien",
               name: "Le Parisien Sport",
               feedURL: "https://feeds.leparisien.fr/leparisien/rss/sport",
               type: .newspaper, country: "FR", language: "fr", city: "Paris",
               reliability: 3, tags: ["France", "Paris"], affiliation: "PSG", twitterHandle: nil, isEnabled: true),

        Source(id: "le10sport",
               name: "Le10Sport",
               feedURL: "https://www.le10sport.com/rss",
               type: .website, country: "FR", language: "fr", city: "Paris",
               reliability: 2, tags: ["France", "Mercato", "Putaclick"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        Source(id: "footmercato",
               name: "Foot Mercato",
               feedURL: "https://www.footmercato.net/rss.xml",
               type: .website, country: "FR", language: "fr", city: "Paris",
               reliability: 2, tags: ["France", "Mercato"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        // ── Espagne ──────────────────────────────────────────
        Source(id: "marca",
               name: "Marca",
               feedURL: "https://www.marca.com/rss/futbol.xml",
               type: .newspaper, country: "ES", language: "es", city: "Madrid",
               reliability: 3, tags: ["Espagne", "Madrid"], affiliation: "Real Madrid", twitterHandle: nil, isEnabled: true),

        Source(id: "as_es",
               name: "AS",
               feedURL: "https://feeds.as.com/mrss-s/pages/as/site/as.com/section/futbol/subsection/primera/",
               type: .newspaper, country: "ES", language: "es", city: "Madrid",
               reliability: 3, tags: ["Espagne", "Madrid"], affiliation: "Real Madrid", twitterHandle: nil, isEnabled: true),

        Source(id: "sport_es",
               name: "Sport",
               feedURL: "https://www.sport.es/rss/futbol.xml",
               type: .newspaper, country: "ES", language: "es", city: "Barcelone",
               reliability: 2, tags: ["Espagne", "Barcelone"], affiliation: "FC Barcelone", twitterHandle: nil, isEnabled: true),

        Source(id: "mundodeportivo",
               name: "Mundo Deportivo",
               feedURL: "https://www.mundodeportivo.com/rss/futbol.xml",
               type: .newspaper, country: "ES", language: "es", city: "Barcelone",
               reliability: 2, tags: ["Espagne", "Barcelone"], affiliation: "FC Barcelone", twitterHandle: nil, isEnabled: true),

        // ── Italie ───────────────────────────────────────────
        Source(id: "gazzetta",
               name: "La Gazzetta dello Sport",
               feedURL: "https://www.gazzetta.it/rss/calcio.xml",
               type: .newspaper, country: "IT", language: "it", city: "Milan",
               reliability: 4, tags: ["Italie", "Généraliste"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        Source(id: "corriere_sport",
               name: "Corriere dello Sport",
               feedURL: "https://www.corrieredellosport.it/rss/calcio.xml",
               type: .newspaper, country: "IT", language: "it", city: "Rome",
               reliability: 3, tags: ["Italie", "Rome"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        Source(id: "tuttosport",
               name: "Tuttosport",
               feedURL: "https://www.tuttosport.com/rss/calcio.xml",
               type: .newspaper, country: "IT", language: "it", city: "Turin",
               reliability: 2, tags: ["Italie", "Turin"], affiliation: "Juventus", twitterHandle: nil, isEnabled: true),

        // ── Allemagne ────────────────────────────────────────
        Source(id: "kicker",
               name: "Kicker",
               feedURL: "https://www.kicker.de/news/fussball/bundesliga/startseite/aktuell/-/rss.xml",
               type: .newspaper, country: "DE", language: "de", city: "Nuremberg",
               reliability: 4, tags: ["Allemagne", "Généraliste"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        Source(id: "bild",
               name: "Bild Sport",
               feedURL: "https://www.bild.de/rss-feeds/rss-sport-fussball-28919242.bild.xml",
               type: .newspaper, country: "DE", language: "de", city: "Berlin",
               reliability: 2, tags: ["Allemagne", "Tabloïd"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        // ── Angleterre ───────────────────────────────────────
        Source(id: "guardian_football",
               name: "The Guardian Football",
               feedURL: "https://www.theguardian.com/football/rss",
               type: .newspaper, country: "GB", language: "en", city: "Londres",
               reliability: 5, tags: ["Angleterre", "Qualité"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        Source(id: "bbc_sport",
               name: "BBC Sport Football",
               feedURL: "https://feeds.bbci.co.uk/sport/football/rss.xml",
               type: .newspaper, country: "GB", language: "en", city: "Londres",
               reliability: 5, tags: ["Angleterre", "Service public"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        Source(id: "sky_sports",
               name: "Sky Sports Football",
               feedURL: "https://www.skysports.com/rss/12040",
               type: .newspaper, country: "GB", language: "en", city: "Londres",
               reliability: 3, tags: ["Angleterre"], affiliation: nil, twitterHandle: nil, isEnabled: true),

        // ── Journalistes ─────────────────────────────────────
        Source(id: "fabrizio_romano",
               name: "Fabrizio Romano",
               feedURL: "https://nitter.poast.org/FabrizioRomano/rss",
               type: .journalist, country: "IT", language: "en", city: "Londres",
               reliability: 5, tags: ["Mercato", "Here we go"], affiliation: nil, twitterHandle: "FabrizioRomano", isEnabled: true),

        Source(id: "david_ornstein",
               name: "David Ornstein",
               feedURL: "https://nitter.poast.org/David_Ornstein/rss",
               type: .journalist, country: "GB", language: "en", city: "Londres",
               reliability: 5, tags: ["Mercato", "Premier League", "The Athletic"], affiliation: nil, twitterHandle: "David_Ornstein", isEnabled: true),

        Source(id: "matteo_moretto",
               name: "Matteo Moretto",
               feedURL: "https://nitter.poast.org/MatteMoretto/rss",
               type: .journalist, country: "IT", language: "es", city: "Barcelone",
               reliability: 4, tags: ["Mercato", "Liga", "Serie A"], affiliation: nil, twitterHandle: "MatteMoretto", isEnabled: true),

        Source(id: "romain_molina",
               name: "Romain Molina",
               feedURL: "https://nitter.poast.org/Romain_Molina/rss",
               type: .journalist, country: "FR", language: "fr", city: "Paris",
               reliability: 4, tags: ["Investigation", "Afrique", "Coulisses"], affiliation: nil, twitterHandle: "Romain_Molina", isEnabled: true),

        Source(id: "ekrem_konur",
               name: "Ekrem Konur",
               feedURL: "https://nitter.poast.org/Ekremkonur/rss",
               type: .journalist, country: "TR", language: "en", city: "Istanbul",
               reliability: 2, tags: ["Mercato", "Turquie"], affiliation: nil, twitterHandle: "Ekremkonur", isEnabled: true),
    ]
}
