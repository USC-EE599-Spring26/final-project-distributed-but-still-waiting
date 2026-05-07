//
//  StreakManager.swift
//  OCKSample
//
//  Created by Jai Shah on 03/04/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import os
import ParseSwift

@MainActor
final class StreakManager {

    static let shared = StreakManager()

    private let streakKey = "current_streak"
    private let lastDateKey = "last_active_date"
    private let longestKey = "longest_streak"

    private let calendar = Calendar.current

    // MARK: - Public

    func handleAppLaunch() {

        if !hasRecordedToday() {
            let streak = recordActivity()
            Logger.streak.info("App open streak updated: \(streak, privacy: .public)")

            NotificationCenter.default.post(name: .streakUpdated, object: nil)
        } else {
            Logger.streak.debug("Streak already recorded today")
        }
    }

    func initializeStreak() async {
        await loadFromParse()
        handleAppLaunch()
    }

    func recordActivity() -> Int {
        let today = calendar.startOfDay(for: Date())
        let lastDate = getLastActiveDate()
        Logger.streak.info("Recording streak activity for today")
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
        let longest = UserDefaults.standard.integer(forKey: longestKey)
        let current = getCurrentStreak()

        if current > longest {
            UserDefaults.standard.set(current, forKey: longestKey)
            return current
        }

        return longest
    }

    func hasRecordedToday() -> Bool {
        guard let lastDate = getLastActiveDate() else { return false }
        return calendar.isDateInToday(lastDate)
    }

    func saveToParse(current: Int, longest: Int, lastDate: Date) async {
        do {
            var user = try await User.current()
            user = try await user.fetch()

            let serverLongest = user.longestStreak ?? 0

            user.currentStreak = current
            user.lastActiveDate = lastDate
            Logger.streak.debug("Saving streak for user: \(user.objectId ?? "nil", privacy: .public)")

            if longest > serverLongest {
                user.longestStreak = longest
                try await user.save()
                Logger.streak.info("Str sent to Parse: \(current, privacy: .public)")
                Logger.streak.info("Longest streak sent to Parse: \(longest, privacy: .public)")
            } else {
                try await user.save()
                Logger.streak.info("Str sent to Parse: \(current, privacy: .public)")
                Logger.streak.info("Longest streak kept server version: \(serverLongest, privacy: .public)")
                if serverLongest > longest {
                    UserDefaults.standard.set(serverLongest, forKey: longestKey)
                    NotificationCenter.default.post(name: .streakUpdated, object: nil)
                }
            }
        } catch {
            Logger.streak.error("Failed to save streak: \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadFromParse() async {
        do {
            var user = try await User.current()
            user = try await user.fetch()

            let current = user.currentStreak ?? 0
            let longest = user.longestStreak ?? 0
            let lastDate = user.lastActiveDate

            // Save locally

            UserDefaults.standard.set(current, forKey: streakKey)
            UserDefaults.standard.set(longest, forKey: longestKey)
            UserDefaults.standard.set(lastDate, forKey: lastDateKey)

            Logger.streak.info("Str loaded :\(current, privacy: .public), longest=\(longest, privacy: .public)")

        } catch {
            Logger.streak.error("Failed to load streak from Parse: \(error.localizedDescription, privacy: .public)")
        }
    }

    func resetLocalStreak() {
        UserDefaults.standard.removeObject(forKey: streakKey)
        UserDefaults.standard.removeObject(forKey: lastDateKey)
        UserDefaults.standard.removeObject(forKey: longestKey)

        Logger.streak.info("Local streak reset")

        NotificationCenter.default.post(name: .streakUpdated, object: nil)
    }

    // MARK: - Private

    private func getLastActiveDate() -> Date? {
        UserDefaults.standard.object(forKey: lastDateKey) as? Date
    }

    private func save(streak: Int, lastDate: Date, longest: Int) {
        Logger.streak.debug("Saving str locally:\(streak, privacy: .public), longest=\(longest, privacy: .public)")
        UserDefaults.standard.set(streak, forKey: streakKey)
        UserDefaults.standard.set(lastDate, forKey: lastDateKey)
        UserDefaults.standard.set(longest, forKey: longestKey)
        Task {
            await saveToParse(
                current: streak,
                longest: longest,
                lastDate: lastDate
            )
        }
    }
}
