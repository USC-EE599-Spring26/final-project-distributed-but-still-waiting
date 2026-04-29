//
//  Stroop.swift
//  OCKSample
//
//  Created by Jai Shah on 4/27/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import os.log
#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)
import ResearchKit
import ResearchKitActiveTask
#endif

struct Stroop: Surveyable {
    static var surveyType: Survey {
        .stroop
    }

    static func identifier() -> String {
        TaskID.stroop
    }
}

#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)

private enum StroopOutcomeKind {
    static let correct = "correct"
    static let incorrect = "incorrect"
    static let reactionTime = "reactionTime"
}

func makeStroopTask() -> ORKOrderedTask {
    let intendedUseDescription = String(localized: "STROOP_INTENDED_USE")

    let stroopTask = ORKOrderedTask.stroopTask(
        withIdentifier: Stroop.identifier(),
        intendedUseDescription: intendedUseDescription,
        numberOfAttempts: 20,
        options: [.excludeConclusion]
    )

    let completionStep = ORKCompletionStep(identifier: "completion")
    completionStep.title = String(localized: "STROOP_COMPLETION_TITLE")
    completionStep.detailText = String(localized: "STROOP_COMPLETION_DETAIL")

    stroopTask.addSteps(from: [completionStep])
    return stroopTask
}

extension Stroop {
    func createSurvey() -> ORKTask {
        makeStroopTask()
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        let stepResults = result.results?.compactMap { $0 as? ORKStepResult } ?? []

        guard let stroopResults = stepResults
            .reversed()
            .compactMap({ stepResult -> [ORKStroopResult]? in
                let results = stepResult.results?.compactMap { $0 as? ORKStroopResult } ?? []
                return results.isEmpty ? nil : results
            })
            .first,
            !stroopResults.isEmpty else {
            Logger.feed.warning("Failed to parse stroop task result for task: \(Self.identifier())")
            assertionFailure("Failed to parse stroop task result")
            return nil
        }

        let scoredResults = stroopResults.filter { $0.colorSelected != nil }
        guard !scoredResults.isEmpty else {
            Logger.feed.warning("Stroop task did not contain any scored attempts for task: \(Self.identifier())")
            assertionFailure("Stroop task did not contain any scored attempts")
            return nil
        }

        let numberOfCorrect = scoredResults.reduce(into: 0) { total, currentResult in
            let expected = normalizedColorValue(currentResult.color)
            let selected = normalizedColorValue(currentResult.colorSelected)
            if expected == selected {
                total += 1
            }
        }
        let numberOfIncorrect = scoredResults.count - numberOfCorrect
        let averageResponseTime = scoredResults
            .map { max(0, $0.endTime - $0.startTime) }
            .reduce(0, +) / Double(scoredResults.count)

        var correct = OCKOutcomeValue(Double(numberOfCorrect))
        correct.kind = StroopOutcomeKind.correct

        var incorrect = OCKOutcomeValue(Double(numberOfIncorrect))
        incorrect.kind = StroopOutcomeKind.incorrect

        var reactionTime = OCKOutcomeValue(averageResponseTime)
        reactionTime.kind = StroopOutcomeKind.reactionTime

        return [correct, incorrect, reactionTime]
    }
}

private func normalizedColorValue(_ color: String?) -> String {
    (color ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
}

#endif
