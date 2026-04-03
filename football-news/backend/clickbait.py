"""
Clickbait detection for football news headlines.
Returns a score from 0.0 (clean) to 1.0 (maximum clickbait)
plus a list of human-readable flags explaining why.
"""
import re
from typing import Tuple

# Patterns ordered by severity weight
CLICKBAIT_PATTERNS = [
    # Rumour laundering (high weight)
    (r"\b(selon|d'après|sources?|insider|il semblerait|on dit|rumeur|bruit)\b", 0.20, "Source vague"),
    (r"\b(according to|sources? say|insider|rumoured?|reportedly|it is said)\b", 0.20, "Source vague"),
    # Urgency / hype words
    (r"\b(imminent|imminente|imminent!|IMMINENT)\b", 0.15, "Urgence artificielle"),
    (r"\b(breaking|urgent|exclu|exclusif|flash)\b", 0.10, "Urgence artificielle"),
    (r"\b(done deal|deal done|officiel|official|confirmed|confirmé)\b", 0.05, "Confirmation prématurée"),
    # Vague subjects
    (r"\b(un club|une équipe|un grand club|un top club|a club|a big club|a top club)\b", 0.15, "Sujet volontairement vague"),
    (r"\b(un joueur|a player|une star|a star)\b(?! de | du | des | d')", 0.10, "Sujet volontairement vague"),
    # Sensational superlatives
    (r"\b(incroyable|unbelievable|incredible|fou|folie|crazy|choquant|shocking|scandale|scandal)\b", 0.10, "Sensationnalisme"),
    (r"\b(énorme|huge|massive|monster|record|historique|historic)\b", 0.05, "Sensationnalisme"),
    # Clickbait hooks
    (r"\b(vous ne croirez pas|you won't believe|on vous dit tout|tout ce que vous devez savoir)\b", 0.25, "Appât au clic"),
    (r"\b(ce qui se passe vraiment|the truth about|la vérité sur|les coulisses)\b", 0.15, "Appât au clic"),
    (r"\b(voici pourquoi|here's why|here is why|c'est pour ça)\b", 0.10, "Appât au clic"),
    # Excessive punctuation / caps
    (r"!{2,}", 0.15, "Ponctuation excessive"),
    (r"\?{2,}", 0.10, "Ponctuation excessive"),
    (r"[A-ZÉÈÀÙÂÊÎÔÛ]{5,}", 0.10, "MAJUSCULES excessives"),
    # Numbers bait
    (r"\b\d+\s*(millions?|M€|M\$|milliards?|billions?)\b.*\b(offre|bid|deal|proposition)\b", 0.05, "Montant sensationnel"),
    # Conditional / speculative
    (r"\b(pourrait|could|might|peut-être|perhaps|maybe|si jamais|if ever)\b", 0.10, "Conditionnel spéculatif"),
    (r"\b(envisage|considers?|mulling|piste|option)\b", 0.08, "Conditionnel spéculatif"),
]

# Patterns that REDUCE the clickbait score (signals of quality)
QUALITY_PATTERNS = [
    (r"\b(officialise|officialisé|communiqué|communique|annonce officielle|official announcement)\b", -0.15),
    (r"\b(bilan|analyse|décryptage|interview|entretien|rapport|report)\b", -0.10),
    (r"\b(statistiques?|stats?|données?|data|chiffres?)\b", -0.05),
]


def detect_clickbait(title: str) -> Tuple[float, list[str]]:
    """
    Returns (score, flags).
    score: float 0.0–1.0
    flags: list of human-readable detected issues
    """
    lower = title.lower()
    score = 0.0
    flags: list[str] = []
    seen_flags: set[str] = set()

    for pattern, weight, label in CLICKBAIT_PATTERNS:
        if re.search(pattern, lower, re.IGNORECASE):
            score += weight
            if label not in seen_flags:
                flags.append(label)
                seen_flags.add(label)

    for pattern, weight in QUALITY_PATTERNS:
        if re.search(pattern, lower, re.IGNORECASE):
            score += weight  # weight is negative

    score = max(0.0, min(1.0, score))
    return round(score, 3), flags


def compute_final_score(source_reliability: int, clickbait_score: float) -> float:
    """
    Combine source reliability (1-5) and clickbait penalty into a 1-5 score.
    Clickbait at 1.0 removes up to 2 points from the reliability score.
    """
    penalty = clickbait_score * 2.0
    raw = source_reliability - penalty
    return round(max(1.0, min(5.0, raw)), 2)


def reliability_label(score: float) -> str:
    if score >= 4.5:
        return "Très fiable"
    if score >= 3.5:
        return "Fiable"
    if score >= 2.5:
        return "À vérifier"
    if score >= 1.5:
        return "Peu fiable"
    return "Putaclick"
