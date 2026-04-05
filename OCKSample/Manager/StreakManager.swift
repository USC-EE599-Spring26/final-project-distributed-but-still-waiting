//
//  StreakManager.swift
//  OCKSample
//
//  Created by Jai Shah on 03/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import os

@MainActor
final class StreakManager {

    static let shared = StreakManager()

    private let streakKey = "current_streak"
    private let lastDateKey = "last_active_date"
    private let longestKey = "longest_streak"
    private var hasHandledLaunch = false

    private let calendar = Calendar.current

    // MARK: - Public

    func handleAppLaunch() {
        guard !hasHandledLaunch else { return }
        hasHandledLaunch = true

        if !hasRecordedToday() {
            let streak = recordActivity()
            Logger.streak.info("🔥 App open streak updated: \(streak, privacy: .public)")

            NotificationCenter.default.post(name: .streakUpdated, object: nil)
        } else {
            Logger.streak.debug("Streak already recorded today")
        }
    }

    func recordActivity() -> Int {
        let today = calendar.startOfDay(for: Date())
        let lastDate = getLastActiveDate()

        var currentStreak = getCurrentStreak()
        var longestStreak = getLongestStreak()

        if let lastDate {
            let daysBetween = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0

            if daysBetween == 1 {
                currentStreak += 1
            } else if daysBetween > 1 {
                currentStreak = 1
            }
            // if 0 → already counted today
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)

        save(streak: currentStreak, lastDate: today, longest: longestStreak)

        return currentStreak
    }

    func getCurrentStreak() -> Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }

    func getLongestStreak() -> Int {
        UserDefaults.standard.integer(forKey: longestKey)
    }

    func hasRecordedToday() -> Bool {
        let today = calendar.startOfDay(for: Date())
        return getLastActiveDate() == today
    }

    // MARK: - Private

    private func getLastActiveDate() -> Date? {
        UserDefaults.standard.object(forKey: lastDateKey) as? Date
    }

    private func save(streak: Int, lastDate: Date, longest: Int) {
        UserDefaults.standard.set(streak, forKey: streakKey)
        UserDefaults.standard.set(lastDate, forKey: lastDateKey)
        UserDefaults.standard.set(longest, forKey: longestKey)
    }
}
