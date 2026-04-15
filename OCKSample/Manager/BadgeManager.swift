import Foundation

@MainActor
final class BadgeManager {

    static let shared = BadgeManager()

    // MARK: - Public API

    func getBadges() -> [Badge] {
        var badges: [Badge] = []

        if let streakBadge = getStreakBadge() {
            badges.append(streakBadge)
        }

        if let phqBadge = getPHQBadge() {
            badges.append(phqBadge)
        }
        // Future categories go here:
        // if let runBadge = getRunBadge() { badges.append(runBadge) }

        return badges
    }

    // MARK: - Streak Badge Logic

    private func getStreakBadge() -> Badge? {
        let streak = StreakManager.shared.getLongestStreak()

        // Highest tier first (IMPORTANT)
        if streak >= 30 {
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
            return Badge(
                id: "streak_bronze",
                titleKey: "badge_streak_3_title",
                descriptionKey: "badge_streak_3_desc",
                tier: .bronze,
                category: .streak,
                isUnlocked: true
            )
        }

        // Optional: show locked badge (recommended for UX)
        return Badge(
            id: "streak_locked",
            titleKey: "badge_streak_3_title",
            descriptionKey: "badge_streak_3_desc",
            tier: .bronze,
            category: .streak,
            isUnlocked: false
        )
    }

    // PH9
    private func getPHQBadge() -> Badge? {

        let phqStreak = UserDefaults.standard.integer(forKey: "phq_streak")

        if phqStreak >= 30 {
            return Badge(
                id: "phq_gold",
                titleKey: "badge_phq_30_title",
                descriptionKey: "badge_phq_30_desc",
                tier: .gold,
                category: .phq,
                isUnlocked: true
            )
        }

        if phqStreak >= 7 {
            return Badge(
                id: "phq_silver",
                titleKey: "badge_phq_7_title",
                descriptionKey: "badge_phq_7_desc",
                tier: .silver,
                category: .phq,
                isUnlocked: true
            )
        }

        if phqStreak >= 3 {
            return Badge(
                id: "phq_bronze",
                titleKey: "badge_phq_3_title",
                descriptionKey: "badge_phq_3_desc",
                tier: .bronze,
                category: .phq,
                isUnlocked: true
            )
        }

        return Badge(
            id: "phq_locked",
            titleKey: "badge_phq_3_title",
            descriptionKey: "badge_phq_3_desc",
            tier: .bronze,
            category: .phq,
            isUnlocked: false
        )
    }
}
