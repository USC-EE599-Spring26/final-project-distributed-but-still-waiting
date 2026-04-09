/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import os.log
#if canImport(ResearchKit) && canImport(ResearchKitUI)
import ResearchKit
import ResearchKitUI
#endif
import ResearchKitSwiftUI
import SwiftUI
import UIKit

// swiftlint:disable type_body_length

@MainActor
final class CareViewController: OCKDailyPageViewController, @unchecked Sendable {

	private var isSyncing = false
	private var isLoading = false
    // State
	private var selectedCarePlanUUID: UUID?
	private var availableTabs: [CarePlanSliderView.Tab] = []
    private var tasksByDate: [Date: [any OCKAnyTask]] = [:]
    private var taskControllersByDate: [Date: [UIViewController]] = [:]

    // UI References
    private var sliderHostingController: UIHostingController<CarePlanSliderView>?
    private var tipView: TipView?

	private let swiftUIPadding: CGFloat = 15
	private var style: Styler {
		CustomStylerKey.defaultValue
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .refresh,
			target: self,
			action: #selector(synchronizeWithRemote)
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(synchronizeWithRemote),
			name: Notification.Name(
				rawValue: Constants.requestSync
			),
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(updateSynchronizationProgress(_:)),
			name: Notification.Name(rawValue: Constants.progressUpdate),
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(reloadView(_:)),
			name: Notification.Name(rawValue: Constants.finishedAskingForPermission),
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(reloadView(_:)),
			name: Notification.Name(rawValue: Constants.shouldRefreshView),
			object: nil
		)
	}

	@objc private func updateSynchronizationProgress(
		_ notification: Notification
	) {
		guard let receivedInfo = notification.userInfo as? [String: Any],
			let progress = receivedInfo[Constants.progressUpdate] as? Int else {
			return
		}

		switch progress {
		case 100:
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(
				title: "\(progress)",
				style: .plain, target: self,
				action: #selector(self.synchronizeWithRemote)
			)
			self.navigationItem.rightBarButtonItem?.tintColor = self.view.tintColor

			// Give sometime for the user to see 100
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
				guard let self else { return }
				self.navigationItem.rightBarButtonItem = UIBarButtonItem(
					barButtonSystemItem: .refresh,
					target: self,
					action: #selector(self.synchronizeWithRemote)
				)
				self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
			}
		default:
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(
				title: "\(progress)",
				style: .plain, target: self,
				action: #selector(self.synchronizeWithRemote)
			)
			self.navigationItem.rightBarButtonItem?.tintColor = self.view.tintColor
		}
	}

	@objc private func synchronizeWithRemote() {
		guard !isSyncing else {
			return
		}
		isSyncing = true

		Task {
			await StreakManager.shared.loadFromParse()
		}

		AppDelegateKey.defaultValue?.store.synchronize { error in
			let errorString = error?.localizedDescription ?? "Successful sync with remote!"
			Logger.feed.info("\(errorString)")
			DispatchQueue.main.async { [weak self] in
				guard let self else { return }
				if error != nil {
					self.navigationItem.rightBarButtonItem?.tintColor = .red
				} else {
					self.navigationItem.rightBarButtonItem?.tintColor = self.navigationItem.leftBarButtonItem?.tintColor
				}
				self.isSyncing = false
			}
		}
	}

	@objc private func reloadView(_ notification: Notification? = nil) {
		guard !isLoading else {
			return
		}
		self.reload()
	}

	/*
	 This will be called each time the selected date changes.
	 Use this as an opportunity to rebuild the content shown to the user.
	 */
	override func dailyPageViewController(
		_ dailyPageViewController: OCKDailyPageViewController,
		prepare listViewController: OCKListViewController,
		for date: Date
	) {
		self.isLoading = true

		// Always call this method to ensure dates for
		// queries are correct.
		Task {
			#if canImport(ResearchKit)
			guard await Utility.checkIfOnboardingIsComplete() else {

				let onboardSurvey = Onboard()
				var query = OCKEventQuery(for: Date())
				query.taskIDs = [Onboard.identifier()]
				let onboardCard = OCKSurveyTaskViewController(
					eventQuery: query,
					store: self.store,
					survey: onboardSurvey.createSurvey(),
					extractOutcome: { _ in
						// Need to call reload sometime in the future
						// since the OCKSurveyTaskViewControllerDelegate
						// is broken.
						DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
							self.reload()
						}
						return [OCKOutcomeValue(Date())]
					}
				)
				onboardCard.surveyDelegate = self
				listViewController.clear()
				listViewController.appendViewController(
					onboardCard,
					animated: false
				)
				self.isLoading = false
				return
			}

			// Always call this method to ensure dates for
			// queries are correct.
			let date = modifyDateIfNeeded(date)

			let isCurrentDay = isSameDay(as: date)

            // 1. Add the Care Plan Slider
            if availableTabs.isEmpty {
                await fetchCarePlans()
            }

            let hvc = UIHostingController(rootView: makeSliderView(for: date, listViewController: listViewController))
            hvc.view.backgroundColor = .clear
            self.sliderHostingController = hvc
            listViewController.appendViewController(hvc, animated: false)

			// 2. Only show the tip view on the current date
			if isCurrentDay {
				if Calendar.current.isDate(date, inSameDayAs: Date()) {
					// Add a non-CareKit view into the list
					let tipTitle = "Benefits of CBT Exercises"
					let tipText = "Learn how CBT exercises can decrease symptoms of depression and anxiety."
					let tip = TipView()
					tip.headerView.titleLabel.text = tipTitle
					tip.headerView.detailLabel.text = tipText
					tip.imageView.image = UIImage(named: "NeuroMalleaBackground")
					tip.customStyle = CustomStylerKey.defaultValue
                    self.tipView = tip
					listViewController.appendView(tip, animated: false)
				}
			}
			#endif

			await fetchAndDisplayTasks(on: listViewController, for: date)
		}
	}

	private func fetchAndDisplayTasks(
		on listViewController: OCKListViewController,
		for date: Date
	) async {
        // Fetch ALL tasks regardless of care plan first to cache them
		let allTasks = await self.fetchAllTasks(on: date)
        self.tasksByDate[date] = allTasks

        // Filter tasks based on selection
        let filteredTasks = filterTasks(allTasks, by: selectedCarePlanUUID)
		appendTasks(filteredTasks, to: listViewController, date: date)
	}

    private func updateDisplayedTasks(
        on listViewController: OCKListViewController,
        for date: Date
    ) async {
        listViewController.clear()

        if let slider = sliderHostingController {
            listViewController.appendViewController(slider, animated: false)
        }

        if let tip = tipView {
            listViewController.appendView(tip, animated: false)
        }

        let allTasks: [any OCKAnyTask]
        if let cachedTasks = tasksByDate[date] {
            allTasks = cachedTasks
        } else {
            allTasks = await fetchAllTasks(on: date)
            tasksByDate[date] = allTasks
        }

        let filtered = filterTasks(allTasks, by: selectedCarePlanUUID)
        appendTasks(filtered, to: listViewController, date: date)
    }

	private func fetchAllTasks(on date: Date) async -> [any OCKAnyTask] {
		var query = OCKTaskQuery(for: date)
		query.excludesTasksWithNoEvents = true

		do {
			let tasks = try await store.fetchAnyTasks(query: query)

			guard let tasksWithPriority = tasks as? [CareTask] else {
				Logger.feed.warning("Could not cast all tasks to \"CareTask\"")
				return tasks
			}
			let orderedPriorityTasks = tasksWithPriority.sortedByPriority()
			let orderedTasks = orderedPriorityTasks.compactMap { orderedPriorityTask in
				tasks.first(where: { $0.id == orderedPriorityTask.id })
			}

			let orderedTasksWithoutOnboarding = orderedTasks.filter {$0.id != Onboard.identifier()}

			return orderedTasksWithoutOnboarding
		} catch {
			Logger.feed.error("Could not fetch tasks: \(error, privacy: .public)")
			return []
		}
	}

    private func filterTasks(_ tasks: [any OCKAnyTask], by carePlanUUID: UUID?) -> [any OCKAnyTask] {
        guard let carePlanUUID else { return tasks }
        return tasks.filter { task in
            if let standardTask = task as? OCKTask {
                return standardTask.carePlanUUID == carePlanUUID
            }
            if let healthTask = task as? OCKHealthKitTask {
                return healthTask.carePlanUUID == carePlanUUID
            }
            return false
        }
    }

	// swiftlint:disable:next cyclomatic_complexity
	private func taskViewControllers(
		_ task: any OCKAnyTask,
		on date: Date
	) -> [UIViewController]? {

		var query = OCKEventQuery(for: date)
		query.taskIDs = [task.id]

		if let standardTask = task as? OCKTask {

			switch standardTask.card {

			case .button:
				#if os(iOS)
				let card = OCKButtonLogTaskViewController(
					query: query,
					store: self.store
				)

				return [card]

				#else
				return []
				#endif

			case .checklist:
				#if os(iOS)
				let card = OCKChecklistTaskViewController(
					query: query,
					store: self.store
				)

				return [card]

				#else
				return []
				#endif

			case .featured:
				return nil

			case .grid:
				return nil

			case .instruction:
				let card = EventQueryView<InstructionsTaskView>(
					query: query
				)
				.padding(.vertical, swiftUIPadding)
				.formattedHostingController()

				return [card]

			case .link:
				return nil

			case .simple:

				let card = EventQueryView<SimpleTaskView>(
					query: query
				)
				.padding(.vertical, swiftUIPadding)
				.formattedHostingController()

				Logger.feed.debug("Successfully created simple task view for task: \(task.id, privacy: .public)")
				return [card]

			case .survey:
				guard let card = researchSurveyViewController(
					query: query,
					task: standardTask
				) else {
					Logger.feed.warning(
						"Unable to create research survey view controller"
					)
					return nil
				}

				Logger.feed.debug("Successfully created research survey view for task: \(task.id, privacy: .public)")
				return [card]
			#if canImport(ResearchKit) && canImport(ResearchKitUI)
			case .uiKitSurvey:
				guard let surveyTask = task as? OCKTask,
					  let survey = surveyTask.uiKitSurvey else {
					Logger.feed.error("Can only use a survey for an \"OCKTask\", not \(task.id)")
					return nil
				}

				let surveyCard = OCKSurveyTaskViewController(
					eventQuery: query,
					store: self.store,
					survey: survey.type().createSurvey(),
					viewSynchronizer: SurveyViewSynchronizer(),
					extractOutcome: survey.type().extractAnswers
				)
				surveyCard.surveyDelegate = self
				Logger.feed.debug("Successfully created UIKit survey view for task: \(task.id, privacy: .public)")
				return [surveyCard]
			#endif

			case .custom:
				let card = EventQueryView<MyCustomCardView>(
					query: query
				)
				.padding(.vertical, swiftUIPadding)
				.formattedHostingController()

				return [card]

			case .customEnergy:
				let card = EventQueryView<EnergyCardView>(
					query: query
				)
				.padding(.vertical, swiftUIPadding)
				.formattedHostingController()

				return [card]

			default:
				return nil
			}

		} else if let healthTask = task as? OCKHealthKitTask {
			switch healthTask.card {

			case .labeledValue:
				return nil

			case .numericProgress:
				let card = EventQueryView<NumericProgressTaskView>(
					query: query
				)
				.padding(.vertical, swiftUIPadding)
				.formattedHostingController()

				return [card]
			default:
				return nil
			}
		} else {
			return nil
		}

	}

	private func researchSurveyViewController(
		query: OCKEventQuery,
		task: OCKTask
	) -> UIViewController? {

		guard let steps = task.surveySteps else {
			return nil
		}

		let surveyViewController = EventQueryContentView<ResearchSurveyView>(
			query: query
		) {
			EventQueryContentView<ResearchCareForm>(
				query: query
			) {
				ForEach(steps) { step in
					ResearchFormStep(
						title: task.title,
						subtitle: task.instructions
					) {
						ForEach(step.questions) { question in
							question.view()
						}
					}
				}
			}
		}
		.padding(.vertical, swiftUIPadding)
		.formattedHostingController()
		return surveyViewController
	}

	private func appendTasks(
		_ tasks: [any OCKAnyTask],
		to listViewController: OCKListViewController,
		date: Date
	) {
		let isCurrentDay = isSameDay(as: date)
        var newControllers: [UIViewController] = []

		tasks.compactMap {
			let cards = self.taskViewControllers(
				$0,
				on: date
			)
			cards?.forEach {
				if let carekitView = $0.view as? OCKView {
					carekitView.customStyle = style
				}
				$0.view.isUserInteractionEnabled = isCurrentDay
				$0.view.alpha = !isCurrentDay ? 0.4 : 1.0
			}
			return cards
		}.forEach { (cards: [UIViewController]) in
			cards.forEach {
				let card = $0
				listViewController.appendViewController(card, animated: true)
                newControllers.append(card)
			}
		}

        // Track the added controllers for this date
        self.taskControllersByDate[date] = newControllers
		self.isLoading = false
	}
}

private extension CareViewController {
	func isSameDay(as date: Date) -> Bool {
		Calendar.current.isDate(
			date,
			inSameDayAs: Date()
		)
	}

	func modifyDateIfNeeded(_ date: Date) -> Date {
		guard date < .now else {
			return date
		}
		guard !isSameDay(as: date) else {
			return .now
		}
		return date.endOfDay
	}

    private func makeSliderView(
        for date: Date,
        listViewController: OCKListViewController
    ) -> CarePlanSliderView {
        CarePlanSliderView(
            carePlans: availableTabs,
            selectedID: Binding(
                get: { self.selectedCarePlanUUID },
                set: { newID in
                    self.selectedCarePlanUUID = newID
                    // Update highlighting
                    self.sliderHostingController?.rootView = self.makeSliderView(
                        for: date,
                        listViewController: listViewController
                    )

                    Task { @MainActor in
                        await self.updateDisplayedTasks(on: listViewController, for: date)
                    }
                }
            )
        )
    }

    private func fetchCarePlans() async {
        do {
            let storeCarePlans = try await store.fetchAnyCarePlans(query: OCKCarePlanQuery())
            let mapped = storeCarePlans.compactMap { plan -> CarePlanSliderView.Tab? in
                guard let carePlan = plan as? OCKCarePlan else { return nil }
                return .init(id: carePlan.uuid, title: carePlan.title)
            }
            self.availableTabs = [.init(id: nil, title: "All Tasks")] + mapped
        } catch {
            Logger.feed.error("Failed to fetch care plans: \(error.localizedDescription)")
        }
    }
}

#if canImport(ResearchKit) && canImport(ResearchKitUI)
extension CareViewController: OCKSurveyTaskViewControllerDelegate {

	/*
	func surveyTask(
		viewController: OCKSurveyTaskViewController,
		for task: OCKAnyTask,
		didFinish result: Result<ORKTaskFinishReason, Error>
	) {
		if case let .success(reason) = result, reason == .completed {
			reload()
		}
	} */
}
#endif

private extension View {
	/// Convert SwiftUI view to UIKit view.
	func formattedHostingController() -> UIHostingController<Self> {
		let viewController = UIHostingController(rootView: self)
		viewController.view.backgroundColor = .clear
		return viewController
	}
}
