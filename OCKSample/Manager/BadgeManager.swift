import Foundation
import os.log

@MainActor
final class BadgeManager {

    static let shared = BadgeManager()

    // MARK: - Public API

    func getBadges() -> [Badge] {
        var badges: [Badge] = []

        if let streakBadge = getStreakBadge() {
            badges.append(streakBadge)
        }

        Logger.badge.info("badges: \(badges.map { $0.id }.joined(separator: ", "))")

        return badges
    }

    // MARK: - Streak Badge Logic

    private func getStreakBadge() -> Badge? {
        let streak = StreakManager.shared.getLongestStreak()
        Logger.badge.debug("Evaluating streak badge: longestStreak=\(streak, privacy: .public)")

        // Highest tier first (IMPORTANT)
        if streak >= 30 {
            Logger.badge.info("Unlocked streak gold badge")
            return Badge(
                id: "streak_gold",
                titleKey: "badge_streak_30_title",
                descriptionKey: "badge_streak_30_desc",
                tier: .gold,
                category: .streak,
                isUnlocked: true
            )
        }

        if streak >= 7 {
            Logger.badge.info("Unlocked streak silver badge")
            return Badge(
                id: "streak_silver",
                titleKey: "badge_streak_7_title",
                descriptionKey: "badge_streak_7_desc",
                tier: .silver,
                category: .streak,
                isUnlocked: true
            )
        }

        if streak >= 3 {
            Logger.badge.info("Unlocked streak bronze badge")
            return Badge(
                id: "streak_bronze",
                titleKey: "badge_streak_3_title",
                descriptionKey: "badge_streak_3_desc",
                tier: .bronze,
                category: .streak,
                isUnlocked: true
            )
        }

        Logger.badge.debug("Streak badge locked: streak=\(streak, privacy: .public) (need >= 3)")
        return Badge(
            id: "streak_locked",
            titleKey: "badge_streak_3_title",
            descriptionKey: "badge_streak_3_desc",
            tier: .bronze,
            category: .streak,
            isUnlocked: false
        )
    }
}
