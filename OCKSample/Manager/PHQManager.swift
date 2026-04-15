import Foundation
import os

@MainActor
final class PHQManager {

    static let shared = PHQManager()

    // MARK: - Keys

    private let streakKey = "phq_streak"
    private let lastDateKey = "phq_last_completion_date"
    private let surveyStartedKey = "phq_survey_started"
    private let calendar = Calendar.current

    // MARK: - Public API

    func handleSurveyReturn() {
        Logger.streak.info("handleSurveyReturn called")
        guard didStartSurvey() else {
                return
            }
            clearSurveyStarted()
        let today = calendar.startOfDay(for: Date())

        // Prevent multiple increments in same day
        if let lastDate = getLastCompletionDate(),
           calendar.isDate(lastDate, inSameDayAs: today) {
            Logger.streak.debug("PHQ already recorded today")
            return
        }

        recordSurveyCompletion()
    }

    /// Main logic for updating streak
    func recordSurveyCompletion() {
        let today = calendar.startOfDay(for: Date())
        let lastDate = getLastCompletionDate()

        var streak = getCurrentStreak()

        if let lastDate {
            let daysDiff = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0

            if daysDiff == 1 {
                // consecutive day
                streak += 1
            } else if daysDiff > 1 {
                // streak broken
                streak = 1
            }
            // if 0 → same day (already handled above)

        } else {
            // first ever completion
            streak = 1
        }

        // Save
        UserDefaults.standard.set(streak, forKey: streakKey)
        UserDefaults.standard.set(today, forKey: lastDateKey)

        Logger.streak.info("PHQ streak updated: \(streak, privacy: .public)")

        // Notify UI
        NotificationCenter.default.post(name: .streakUpdated, object: nil)
    }

    // MARK: - Getters

    func getCurrentStreak() -> Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }

    func hasRecordedToday() -> Bool {
        guard let lastDate = getLastCompletionDate() else { return false }
        return calendar.isDate(lastDate, inSameDayAs: Date())
    }

    // MARK: - Helpers
    func markSurveyStarted() {
        Logger.streak.info("PHQ survey STARTED")
        UserDefaults.standard.set(true, forKey: surveyStartedKey)
    }

    private func didStartSurvey() -> Bool {
        UserDefaults.standard.bool(forKey: surveyStartedKey)
    }

    private func clearSurveyStarted() {
        UserDefaults.standard.set(false, forKey: surveyStartedKey)
    }

    private func getLastCompletionDate() -> Date? {
        UserDefaults.standard.object(forKey: lastDateKey) as? Date
    }
}
