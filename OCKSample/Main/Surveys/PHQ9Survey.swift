//
//  PHQ9Survey.swift
//  OCKSample
//
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import os.log
#if canImport(ResearchKit)
import ResearchKit
#endif

struct PHQ9Survey: Surveyable {
    static var surveyType: Survey {
        .phq9
    }

    static func identifier() -> String {
        TaskID.phq9Survey
    }
}

enum PHQ9OutcomeKind {
    static let totalScore = "phq9Score"
    static let functionalImpact = "functionalImpact"
    static let timestamp = "timestamp"
    static let q9PositiveFlag = "q9PositiveFlag"
}

enum PHQ9Severity {
    case minimal
    case mild
    case moderate
    case moderatelySevere
    case severe

    init(score: Int) {
        switch score {
        case 0...4:
            self = .minimal
        case 5...9:
            self = .mild
        case 10...14:
            self = .moderate
        case 15...19:
            self = .moderatelySevere
        default:
            self = .severe
        }
    }

    var localizedTitle: String {
        switch self {
        case .minimal:
            return String(localized: "PHQ9_SEVERITY_MINIMAL")
        case .mild:
            return String(localized: "PHQ9_SEVERITY_MILD")
        case .moderate:
            return String(localized: "PHQ9_SEVERITY_MODERATE")
        case .moderatelySevere:
            return String(localized: "PHQ9_SEVERITY_MODERATELY_SEVERE")
        case .severe:
            return String(localized: "PHQ9_SEVERITY_SEVERE")
        }
    }
}

private enum PHQ9Question: Int, CaseIterable {
    case question1 = 1
    case question2 = 2
    case question3 = 3
    case question4 = 4
    case question5 = 5
    case question6 = 6
    case question7 = 7
    case question8 = 8
    case question9 = 9

    var stepIdentifier: String {
        "\(TaskID.phq9)-q\(rawValue)"
    }

    var outcomeKind: String {
        "q\(rawValue)"
    }

    var localizedQuestion: String {
        switch self {
        case .question1:
            return String(localized: "PHQ9_QUESTION1")
        case .question2:
            return String(localized: "PHQ9_QUESTION2")
        case .question3:
            return String(localized: "PHQ9_QUESTION3")
        case .question4:
            return String(localized: "PHQ9_QUESTION4")
        case .question5:
            return String(localized: "PHQ9_QUESTION5")
        case .question6:
            return String(localized: "PHQ9_QUESTION6")
        case .question7:
            return String(localized: "PHQ9_QUESTION7")
        case .question8:
            return String(localized: "PHQ9_QUESTION8")
        case .question9:
            return String(localized: "PHQ9_QUESTION9")
        }
    }
}

#if canImport(ResearchKit)

func makePHQ9SurveyTask() -> ORKOrderedTask {
    let introStep = ORKInstructionStep(identifier: "\(PHQ9Survey.identifier()).intro")
    introStep.title = String(localized: "PHQ9_TASK_TITLE")
    introStep.text = String(localized: "PHQ9_PROMPT")

    let questionSteps = PHQ9Question.allCases.map(makePHQ9QuestionStep)

    let functionalImpactStep = ORKQuestionStep(
        identifier: "\(PHQ9Survey.identifier()).functional-impact"
    )
    functionalImpactStep.title = String(localized: "PHQ9_FUNCTIONAL_IMPACT_QUESTION")
    functionalImpactStep.answerFormat = ORKTextChoiceAnswerFormat(
        style: .singleChoice,
        textChoices: makePHQ9FunctionalImpactChoices()
    )
    functionalImpactStep.isOptional = false

    let reviewStep = ORKReviewStep.embeddedReviewStep(
        withIdentifier: "\(PHQ9Survey.identifier()).review"
    )
    reviewStep.title = String(localized: "PHQ9_REVIEW_TITLE")
    reviewStep.text = String(localized: "PHQ9_REVIEW_DETAIL")
    reviewStep.excludeInstructionSteps = true

    let completionStep = ORKCompletionStep(
        identifier: "\(PHQ9Survey.identifier()).completion"
    )
    completionStep.title = String(localized: "PHQ9_COMPLETION_TITLE")
    completionStep.text = String(localized: "PHQ9_COMPLETION_DETAIL")

    let steps: [ORKStep] = [introStep]
        + questionSteps
        + [functionalImpactStep, reviewStep, completionStep]
    return ORKOrderedTask(identifier: PHQ9Survey.identifier(), steps: steps)
}

extension PHQ9Survey {
    func createSurvey() -> ORKTask {
        makePHQ9SurveyTask()
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        guard let answers = extractPHQ9Answers(from: result) else {
            Logger.feed.warning(
                "Failed to extract PHQ-9 answers for task: \(Self.identifier())"
            )
            assertionFailure("Failed to extract PHQ-9 answers")
            return nil
        }

        guard let functionalImpact = extractChoiceAnswer(
            identifier: "\(Self.identifier()).functional-impact",
            from: result
        ) else {
            Logger.feed.warning(
                "Failed to extract PHQ-9 functional impact answer for task: \(Self.identifier())"
            )
            assertionFailure("Failed to extract PHQ-9 functional impact answer")
            return nil
        }

        let totalScore = answers.values.reduce(0, +)
        let q9PositiveFlag = (answers[.question9] ?? 0) > 0 ? 1.0 : 0.0

        var outcomeValues = PHQ9Question.allCases.map { question -> OCKOutcomeValue in
            var value = OCKOutcomeValue(Double(answers[question] ?? 0))
            value.kind = question.outcomeKind
            return value
        }

        var scoreValue = OCKOutcomeValue(Double(totalScore))
        scoreValue.kind = PHQ9OutcomeKind.totalScore

        var functionalImpactValue = OCKOutcomeValue(Double(functionalImpact))
        functionalImpactValue.kind = PHQ9OutcomeKind.functionalImpact

        var timestampValue = OCKOutcomeValue(Date())
        timestampValue.kind = PHQ9OutcomeKind.timestamp

        var q9FlagValue = OCKOutcomeValue(q9PositiveFlag)
        q9FlagValue.kind = PHQ9OutcomeKind.q9PositiveFlag

        outcomeValues.append(contentsOf: [
            scoreValue,
            functionalImpactValue,
            timestampValue,
            q9FlagValue
        ])

        return outcomeValues
    }
}

private func makePHQ9QuestionStep(_ question: PHQ9Question) -> ORKQuestionStep {
    let step = ORKQuestionStep(identifier: question.stepIdentifier)
    step.title = question.localizedQuestion
    step.answerFormat = ORKTextChoiceAnswerFormat(
        style: .singleChoice,
        textChoices: makePHQ9FrequencyChoices()
    )
    step.isOptional = false
    return step
}

private func makePHQ9FrequencyChoices() -> [ORKTextChoice] {
    [
        ORKTextChoice(
            text: String(localized: "PHQ9_ANSWER_NOT_AT_ALL"),
            value: 0 as NSNumber
        ),
        ORKTextChoice(
            text: String(localized: "PHQ9_ANSWER_SEVERAL_DAYS"),
            value: 1 as NSNumber
        ),
        ORKTextChoice(
            text: String(localized: "PHQ9_ANSWER_MORE_THAN_HALF"),
            value: 2 as NSNumber
        ),
        ORKTextChoice(
            text: String(localized: "PHQ9_ANSWER_NEARLY_EVERY_DAY"),
            value: 3 as NSNumber
        )
    ]
}

private func makePHQ9FunctionalImpactChoices() -> [ORKTextChoice] {
    [
        ORKTextChoice(
            text: String(localized: "PHQ9_FUNCTIONAL_NOT_DIFFICULT"),
            value: 0 as NSNumber
        ),
        ORKTextChoice(
            text: String(localized: "PHQ9_FUNCTIONAL_SOMEWHAT_DIFFICULT"),
            value: 1 as NSNumber
        ),
        ORKTextChoice(
            text: String(localized: "PHQ9_FUNCTIONAL_VERY_DIFFICULT"),
            value: 2 as NSNumber
        ),
        ORKTextChoice(
            text: String(localized: "PHQ9_FUNCTIONAL_EXTREMELY_DIFFICULT"),
            value: 3 as NSNumber
        )
    ]
}

private func extractPHQ9Answers(from result: ORKTaskResult) -> [PHQ9Question: Int]? {
    var answers = [PHQ9Question: Int]()

    for question in PHQ9Question.allCases {
        guard let answer = extractChoiceAnswer(identifier: question.stepIdentifier, from: result) else {
            return nil
        }
        answers[question] = answer
    }

    return answers
}

private func extractChoiceAnswer(identifier: String, from result: ORKTaskResult) -> Int? {
    let stepResults = result.results?.compactMap { $0 as? ORKStepResult } ?? []
    guard let stepResult = stepResults.first(where: { $0.identifier == identifier }),
          let choiceResult = stepResult.results?.first as? ORKChoiceQuestionResult,
          let answer = choiceResult.choiceAnswers?.first as? NSNumber else {
        return nil
    }

    return answer.intValue
}

func phq9Score(from event: OCKAnyEvent) -> Int? {
    guard let outcomeValue = event.outcome?.values.first(where: {
        $0.kind == PHQ9OutcomeKind.totalScore
    }) else {
        return nil
    }

    if let integerValue = outcomeValue.integerValue {
        return integerValue
    }

    if let doubleValue = outcomeValue.doubleValue {
        return Int(doubleValue)
    }

    return nil
}

#endif
