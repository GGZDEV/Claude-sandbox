import Foundation

// MARK: - Clickbait Detector

struct ClickbaitDetector {

    struct Rule {
        let pattern: String
        let weight: Double
        let flag: String
        var options: NSRegularExpression.Options = [.caseInsensitive]
    }

    private static let penaltyRules: [Rule] = [
        // Source vague
        Rule(pattern: #"\b(selon|d'après|sources?|insider|il semblerait|on dit|rumeur)\b"#,
             weight: 0.20, flag: "Source vague"),
        Rule(pattern: #"\b(according to|sources? say|insider|reportedly|it is said|rumoured?)\b"#,
             weight: 0.20, flag: "Source vague"),
        // Urgence artificielle
        Rule(pattern: #"\b(imminent|imminente)\b"#,          weight: 0.15, flag: "Urgence artificielle"),
        Rule(pattern: #"\b(breaking|urgent|exclu|exclusif|flash)\b"#, weight: 0.10, flag: "Urgence artificielle"),
        Rule(pattern: #"\b(done deal|deal done|officiel|confirmed|confirmé)\b"#, weight: 0.05, flag: "Confirmation prématurée"),
        // Sujet vague
        Rule(pattern: #"\b(un club|une équipe|un grand club|un top club|a big club|a top club)\b"#,
             weight: 0.15, flag: "Sujet volontairement vague"),
        // Sensationnalisme
        Rule(pattern: #"\b(incroyable|unbelievable|incredible|fou|folie|crazy|choquant|shocking|scandale)\b"#,
             weight: 0.10, flag: "Sensationnalisme"),
        Rule(pattern: #"\b(énorme|huge|massive|monster|historique|historic)\b"#,
             weight: 0.05, flag: "Sensationnalisme"),
        // Appât au clic
        Rule(pattern: #"\b(vous ne croirez pas|you won't believe|on vous dit tout)\b"#,
             weight: 0.25, flag: "Appât au clic"),
        Rule(pattern: #"\b(ce qui se passe vraiment|the truth about|la vérité sur)\b"#,
             weight: 0.15, flag: "Appât au clic"),
        Rule(pattern: #"\b(voici pourquoi|here's why|here is why)\b"#,
             weight: 0.10, flag: "Appât au clic"),
        // Ponctuation excessive — raw string can't do quantifiers on special chars
        Rule(pattern: "!{2,}",  weight: 0.15, flag: "Ponctuation excessive"),
        Rule(pattern: #"\?{2,}"#, weight: 0.10, flag: "Ponctuation excessive"),
        // Conditionnel spéculatif
        Rule(pattern: #"\b(pourrait|could|might|peut-être|perhaps|maybe)\b"#,
             weight: 0.10, flag: "Conditionnel spéculatif"),
        Rule(pattern: #"\b(envisage|considers?|mulling|piste|option)\b"#,
             weight: 0.08, flag: "Conditionnel spéculatif"),
    ]

    private static let qualityRules: [Rule] = [
        Rule(pattern: #"\b(officialisé|communiqué|annonce officielle|official announcement)\b"#,
             weight: -0.15, flag: ""),
        Rule(pattern: #"\b(bilan|analyse|décryptage|interview|entretien|rapport)\b"#,
             weight: -0.10, flag: ""),
        Rule(pattern: #"\b(statistiques?|données?|chiffres?)\b"#,
             weight: -0.05, flag: ""),
    ]

    // MARK: - MAJUSCULES excessives (cannot use \p in basic NSRegularExpression without unicode flag)
    private static let capsPattern = try? NSRegularExpression(pattern: "[A-ZÉÈÀÙÂÊÎÔÛ]{5,}")

    static func detect(_ title: String) -> (score: Double, flags: [String]) {
        var score = 0.0
        var flags: [String] = []
        var seenFlags = Set<String>()

        for rule in penaltyRules {
            guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: rule.options) else { continue }
            let range = NSRange(title.startIndex..., in: title)
            if regex.firstMatch(in: title, range: range) != nil {
                score += rule.weight
                if !rule.flag.isEmpty, !seenFlags.contains(rule.flag) {
                    flags.append(rule.flag)
                    seenFlags.insert(rule.flag)
                }
            }
        }

        // Caps check
        let capsRange = NSRange(title.startIndex..., in: title)
        if capsPattern?.firstMatch(in: title, range: capsRange) != nil {
            score += 0.10
            let f = "MAJUSCULES excessives"
            if !seenFlags.contains(f) { flags.append(f); seenFlags.insert(f) }
        }

        for rule in qualityRules {
            guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: rule.options) else { continue }
            let range = NSRange(title.startIndex..., in: title)
            if regex.firstMatch(in: title, range: range) != nil {
                score += rule.weight
            }
        }

        let clamped = max(0.0, min(1.0, score))
        return (score: (clamped * 1000).rounded() / 1000, flags: flags)
    }

    static func finalScore(sourceReliability: Int, clickbaitScore: Double) -> Double {
        let penalty = clickbaitScore * 2.0
        let raw = Double(sourceReliability) - penalty
        return max(1.0, min(5.0, (raw * 100).rounded() / 100))
    }
}
