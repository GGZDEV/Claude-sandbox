import SwiftUI

struct ScoreBadge: View {
    let score: Double
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Article.color(for: score))
                .frame(width: 6, height: 6)
            if !compact {
                Text(Article.label(for: score))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Article.color(for: score))
                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Text(score.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Article.color(for: score))
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .background(Article.color(for: score).opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Article.color(for: score).opacity(0.3), lineWidth: 1)
        )
    }
}

struct TagChip: View {
    let text: String
    var isActive: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? Color.accentColor : Color(.tertiaryLabel))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(isActive
                        ? Color.accentColor.opacity(0.15)
                        : Color(.tertiarySystemFill))
                )
                .overlay(
                    Capsule().stroke(
                        isActive ? Color.accentColor.opacity(0.5) : Color.clear,
                        lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct ClickbaitFlag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Color(hex: "#f87171"))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: "#2d1a1a"))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(hex: "#5c2e2e"), lineWidth: 1)
            )
    }
}

struct AffiliationBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Color(hex: "#a5b4fc"))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Color(hex: "#1e1b4b").opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color(hex: "#6366f1").opacity(0.4), lineWidth: 1)
            )
    }
}
