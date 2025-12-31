import Foundation

/// Rule-based planning service that generates personalized goal schedules
/// Works entirely on-device without requiring any external API
final class RuleBasedPlanningService: AIServiceProtocol {

    // MARK: - Generate Goal Plan
    func generateGoalPlan(
        goal: Goal,
        userProfile: UserProfile,
        existingCommitments: [Event]
    ) async throws -> AISchedule {
        let availableHoursPerWeek = userProfile.weeklyAvailableHours

        // Calculate duration based on target date or estimate
        let targetDate = goal.targetDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date())!
        let totalDays = max(7, Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 90)
        let totalWeeks = max(1, totalDays / 7)

        // Generate personalized phases based on the goal
        let phases = generatePersonalizedPhases(
            goal: goal,
            userProfile: userProfile,
            totalWeeks: totalWeeks,
            hoursPerWeek: availableHoursPerWeek,
            startDate: Date(),
            existingCommitments: existingCommitments
        )

        return AISchedule(
            generatedAt: Date(),
            phases: phases,
            weeklyCommitmentHours: availableHoursPerWeek,
            estimatedCompletionDate: targetDate
        )
    }

    // MARK: - Adjust Schedule
    func adjustSchedule(
        currentSchedule: AISchedule,
        goal: Goal,
        completedTasks: [AISchedule.ScheduledTask],
        missedTasks: [AISchedule.ScheduledTask]
    ) async throws -> AISchedule {
        var adjustedSchedule = currentSchedule

        // Reschedule missed tasks
        if !missedTasks.isEmpty {
            let today = Date()
            var nextAvailableDate = today

            for missedTask in missedTasks {
                for phaseIndex in adjustedSchedule.phases.indices {
                    if let taskIndex = adjustedSchedule.phases[phaseIndex].tasks.firstIndex(where: { $0.id == missedTask.id }) {
                        nextAvailableDate = Calendar.current.date(byAdding: .day, value: 1, to: nextAvailableDate) ?? nextAvailableDate
                        adjustedSchedule.phases[phaseIndex].tasks[taskIndex].scheduledDate = nextAvailableDate
                    }
                }
            }

            adjustedSchedule.addAdjustment(AISchedule.Adjustment(
                reason: .missedTasks,
                description: "Rescheduled \(missedTasks.count) missed task(s)",
                changes: "Tasks moved to upcoming days"
            ))
        }

        let progress = currentSchedule.overallProgress
        let expectedProgress = calculateExpectedProgress(for: currentSchedule)

        if progress > expectedProgress + 0.2 {
            adjustedSchedule.addAdjustment(AISchedule.Adjustment(
                reason: .aheadOfSchedule,
                description: "Great progress! You're ahead of schedule",
                changes: "Keep up the good work"
            ))
        }

        return adjustedSchedule
    }

    // MARK: - Analyze Progress
    func analyzeProgress(
        goal: Goal,
        schedule: AISchedule
    ) async throws -> ProgressAnalysis {
        let completedCount = schedule.completedTasks
        let totalCount = schedule.totalTasks
        let overdueCount = schedule.overdueTasks.count

        let progress = schedule.overallProgress
        let expectedProgress = calculateExpectedProgress(for: schedule)

        var score: Double = progress * 100

        if totalCount > 0 {
            let overdueRatio = Double(overdueCount) / Double(totalCount)
            score -= overdueRatio * 30
        }

        if progress > expectedProgress {
            score += 10
        }

        score = max(0, min(100, score))

        var strengths: [String] = []
        var improvements: [String] = []
        var recommendations: [String] = []

        if progress >= expectedProgress {
            strengths.append("You're on track with \"\(goal.title)\"")
        }

        if completedCount > 0 {
            strengths.append("You've completed \(completedCount) task(s) so far")
        }

        if overdueCount > 0 {
            improvements.append("\(overdueCount) task(s) are overdue")
            recommendations.append("Try to catch up on overdue tasks this week")
        }

        if progress < expectedProgress {
            improvements.append("Progress is slightly behind schedule")
            recommendations.append("Consider dedicating extra time this week")
        }

        if strengths.isEmpty {
            strengths.append("Starting your journey toward \"\(goal.title)\"")
        }

        if recommendations.isEmpty {
            recommendations.append("Keep up the consistent effort")
            recommendations.append("Review upcoming tasks at the start of each week")
        }

        var estimatedNewDate: Date? = nil
        if progress > 0 && progress < 1 {
            let elapsedDays = Calendar.current.dateComponents([.day], from: schedule.generatedAt, to: Date()).day ?? 1
            let estimatedTotalDays = Double(elapsedDays) / progress
            estimatedNewDate = Calendar.current.date(byAdding: .day, value: Int(estimatedTotalDays), to: schedule.generatedAt)
        }

        return ProgressAnalysis(
            analyzedAt: Date(),
            overallScore: score,
            onTrack: overdueCount == 0 && progress >= expectedProgress * 0.9,
            strengths: strengths,
            areasForImprovement: improvements,
            recommendations: recommendations,
            estimatedNewCompletionDate: estimatedNewDate
        )
    }

    // MARK: - Get Suggestions
    func getSuggestions(
        goal: Goal,
        schedule: AISchedule,
        userProfile: UserProfile
    ) async throws -> [String] {
        var suggestions: [String] = []
        let goalTopic = extractTopic(from: goal.title)

        let overdueTasks = schedule.overdueTasks
        let todayTasks = schedule.tasksForToday
        let progress = schedule.overallProgress

        if !overdueTasks.isEmpty {
            suggestions.append("You have \(overdueTasks.count) overdue task(s) for \"\(goal.title)\". Try to complete them today.")
        }

        if todayTasks.isEmpty && !schedule.upcomingTasks.isEmpty {
            suggestions.append("No tasks scheduled for today. Consider working ahead on \(goalTopic).")
        }

        if progress < 0.25 && schedule.totalTasks > 0 {
            suggestions.append("You're in the early stages of \"\(goal.title)\". Building momentum is key!")
        } else if progress >= 0.75 {
            suggestions.append("You're almost done with \"\(goal.title)\"! Stay focused to finish strong.")
        }

        // Category-specific suggestions
        switch goal.category {
        case .fitness:
            suggestions.append("Remember to stay hydrated and get adequate rest between workouts.")
        case .education:
            suggestions.append("Try the Pomodoro technique: 25 minutes of focused study on \(goalTopic), then a 5-minute break.")
        case .career:
            suggestions.append("Network with professionals who have achieved similar goals.")
        case .health:
            suggestions.append("Track your progress in a journal to stay motivated.")
        case .finance:
            suggestions.append("Review your progress weekly to stay on track.")
        case .creativity:
            suggestions.append("Set aside dedicated time for \(goalTopic) without distractions.")
        case .relationships:
            suggestions.append("Quality time matters more than quantity. Be present.")
        case .personal:
            suggestions.append("Celebrate small wins along the way to stay motivated.")
        }

        return suggestions
    }

    // MARK: - Private Helpers

    private func calculateExpectedProgress(for schedule: AISchedule) -> Double {
        let totalDuration = schedule.estimatedCompletionDate.timeIntervalSince(schedule.generatedAt)
        let elapsedDuration = Date().timeIntervalSince(schedule.generatedAt)
        guard totalDuration > 0 else { return 1.0 }
        return min(1.0, max(0, elapsedDuration / totalDuration))
    }

    /// Extract the main topic/subject from the goal title
    private func extractTopic(from title: String) -> String {
        let lowercased = title.lowercased()

        // Remove common prefixes
        let prefixes = ["learn", "become", "get", "start", "improve", "build", "create", "develop", "master", "achieve", "complete", "finish", "be a", "be an", "become a", "become an"]
        var topic = lowercased

        for prefix in prefixes {
            if topic.hasPrefix(prefix + " ") {
                topic = String(topic.dropFirst(prefix.count + 1))
                break
            }
        }

        // Capitalize first letter
        return topic.prefix(1).uppercased() + topic.dropFirst()
    }

    /// Generate personalized phases based on the specific goal
    private func generatePersonalizedPhases(
        goal: Goal,
        userProfile: UserProfile,
        totalWeeks: Int,
        hoursPerWeek: Double,
        startDate: Date,
        existingCommitments: [Event]
    ) -> [AISchedule.Phase] {
        let calendar = Calendar.current
        let goalTopic = extractTopic(from: goal.title)
        let goalDescription = goal.description ?? goal.title

        // Determine phase structure based on goal duration
        let phaseCount: Int
        if totalWeeks <= 2 {
            phaseCount = 2
        } else if totalWeeks <= 6 {
            phaseCount = 3
        } else {
            phaseCount = 4
        }

        let weeksPerPhase = max(1, totalWeeks / phaseCount)
        var phases: [AISchedule.Phase] = []
        var currentDate = startDate

        // Generate phase definitions based on category and goal
        let phaseDefinitions = getPhaseDefinitions(
            category: goal.category,
            topic: goalTopic,
            description: goalDescription,
            phaseCount: phaseCount
        )

        for (index, phaseDef) in phaseDefinitions.enumerated() {
            let phaseStartDate = currentDate
            let phaseEndDate = calendar.date(byAdding: .weekOfYear, value: weeksPerPhase, to: phaseStartDate) ?? phaseStartDate

            // Generate personalized tasks for this phase
            let tasks = generatePersonalizedTasks(
                phase: phaseDef,
                topic: goalTopic,
                category: goal.category,
                phaseIndex: index,
                totalPhases: phaseCount,
                startDate: phaseStartDate,
                endDate: phaseEndDate,
                hoursPerWeek: hoursPerWeek,
                existingCommitments: existingCommitments,
                userInterests: userProfile.interests
            )

            let phase = AISchedule.Phase(
                title: phaseDef.title,
                description: phaseDef.description,
                startDate: phaseStartDate,
                endDate: phaseEndDate,
                tasks: tasks
            )

            phases.append(phase)
            currentDate = calendar.date(byAdding: .day, value: 1, to: phaseEndDate) ?? phaseEndDate
        }

        return phases
    }

    /// Get phase definitions based on category
    private func getPhaseDefinitions(category: GoalCategory, topic: String, description: String, phaseCount: Int) -> [PhaseDefinition] {
        switch category {
        case .education:
            return getEducationPhases(topic: topic, count: phaseCount)
        case .fitness:
            return getFitnessPhases(topic: topic, count: phaseCount)
        case .career:
            return getCareerPhases(topic: topic, count: phaseCount)
        case .health:
            return getHealthPhases(topic: topic, count: phaseCount)
        case .finance:
            return getFinancePhases(topic: topic, count: phaseCount)
        case .creativity:
            return getCreativityPhases(topic: topic, count: phaseCount)
        case .relationships:
            return getRelationshipsPhases(topic: topic, count: phaseCount)
        case .personal:
            return getPersonalPhases(topic: topic, count: phaseCount)
        }
    }

    /// Generate personalized tasks for a phase
    private func generatePersonalizedTasks(
        phase: PhaseDefinition,
        topic: String,
        category: GoalCategory,
        phaseIndex: Int,
        totalPhases: Int,
        startDate: Date,
        endDate: Date,
        hoursPerWeek: Double,
        existingCommitments: [Event],
        userInterests: [String]
    ) -> [AISchedule.ScheduledTask] {
        var tasks: [AISchedule.ScheduledTask] = []
        let calendar = Calendar.current

        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7
        let tasksPerWeek = max(2, Int(hoursPerWeek / 1.0)) // More tasks, shorter duration
        let totalTasksForPhase = max(4, (totalDays / 7 + 1) * tasksPerWeek)

        // Get task templates for this phase
        let taskTemplates = phase.getTaskTemplates(topic: topic, category: category)

        var currentDate = startDate

        for i in 0..<totalTasksForPhase {
            // Skip weekends
            while calendar.isDateInWeekend(currentDate) && currentDate < endDate {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            // Check for conflicts
            let hasConflict = existingCommitments.contains { event in
                event.startDate.isSameDay(as: currentDate)
            }

            if hasConflict {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            guard currentDate <= endDate else { break }

            // Get a task template, cycling through available templates
            let templateIndex = i % taskTemplates.count
            let template = taskTemplates[templateIndex]

            // Create personalized task
            let task = AISchedule.ScheduledTask(
                title: template.title,
                description: template.description,
                scheduledDate: currentDate,
                durationMinutes: template.duration,
                resources: template.resources
            )

            tasks.append(task)

            // Move to next slot
            let daysToAdd = max(1, 7 / tasksPerWeek)
            currentDate = calendar.date(byAdding: .day, value: daysToAdd, to: currentDate) ?? currentDate
        }

        return tasks
    }

    // MARK: - Phase Definitions by Category

    private func getEducationPhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Foundation: Understanding \(topic)",
                description: "Build a solid foundation by learning the core concepts of \(topic)",
                taskTypes: [.research, .study, .practice, .review]
            ),
            PhaseDefinition(
                title: "Core Learning: Mastering \(topic)",
                description: "Dive deeper into \(topic) with focused study and practice",
                taskTypes: [.study, .practice, .project, .review]
            ),
            PhaseDefinition(
                title: "Advanced: Deepening \(topic) Knowledge",
                description: "Tackle advanced concepts and real-world applications",
                taskTypes: [.advancedStudy, .project, .practice, .teach]
            ),
            PhaseDefinition(
                title: "Mastery: Applying \(topic)",
                description: "Apply your knowledge and demonstrate mastery of \(topic)",
                taskTypes: [.project, .teach, .review, .practice]
            )
        ]
        return Array(allPhases.prefix(count))
    }

    private func getFitnessPhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Foundation: Starting \(topic)",
                description: "Build baseline fitness and establish healthy habits for \(topic)",
                taskTypes: [.assessment, .lightActivity, .planning, .tracking]
            ),
            PhaseDefinition(
                title: "Building: Progressing with \(topic)",
                description: "Increase intensity and build strength for \(topic)",
                taskTypes: [.workout, .tracking, .recovery, .planning]
            ),
            PhaseDefinition(
                title: "Intensification: Pushing \(topic) Further",
                description: "Challenge yourself with advanced \(topic) routines",
                taskTypes: [.intenseWorkout, .tracking, .recovery, .assessment]
            ),
            PhaseDefinition(
                title: "Maintenance: Sustaining \(topic)",
                description: "Maintain your gains and make \(topic) a lifestyle",
                taskTypes: [.workout, .planning, .recovery, .celebration]
            )
        ]
        return Array(allPhases.prefix(count))
    }

    private func getCareerPhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Research: Exploring \(topic)",
                description: "Research requirements and opportunities in \(topic)",
                taskTypes: [.research, .networking, .planning, .skillAssessment]
            ),
            PhaseDefinition(
                title: "Preparation: Building \(topic) Skills",
                description: "Develop skills and prepare materials for \(topic)",
                taskTypes: [.skillBuilding, .preparation, .networking, .practice]
            ),
            PhaseDefinition(
                title: "Action: Pursuing \(topic)",
                description: "Take concrete steps toward \(topic)",
                taskTypes: [.application, .networking, .practice, .followUp]
            ),
            PhaseDefinition(
                title: "Achievement: Landing \(topic)",
                description: "Final push to achieve \(topic)",
                taskTypes: [.interview, .negotiation, .followUp, .celebration]
            )
        ]
        return Array(allPhases.prefix(count))
    }

    private func getHealthPhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Awareness: Understanding \(topic)",
                description: "Learn about \(topic) and assess your current state",
                taskTypes: [.research, .assessment, .planning, .tracking]
            ),
            PhaseDefinition(
                title: "Action: Implementing \(topic)",
                description: "Start making changes toward \(topic)",
                taskTypes: [.healthActivity, .tracking, .planning, .review]
            ),
            PhaseDefinition(
                title: "Habit Formation: Establishing \(topic)",
                description: "Build sustainable habits around \(topic)",
                taskTypes: [.healthActivity, .tracking, .review, .adjustment]
            ),
            PhaseDefinition(
                title: "Lifestyle: Living \(topic)",
                description: "Make \(topic) a natural part of your life",
                taskTypes: [.healthActivity, .celebration, .planning, .maintenance]
            )
        ]
        return Array(allPhases.prefix(count))
    }

    private func getFinancePhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Assessment: Analyzing for \(topic)",
                description: "Understand your current financial situation for \(topic)",
                taskTypes: [.assessment, .research, .planning, .tracking]
            ),
            PhaseDefinition(
                title: "Planning: Strategizing \(topic)",
                description: "Create a concrete plan for \(topic)",
                taskTypes: [.planning, .research, .setup, .tracking]
            ),
            PhaseDefinition(
                title: "Execution: Implementing \(topic)",
                description: "Put your \(topic) plan into action",
                taskTypes: [.action, .tracking, .review, .adjustment]
            ),
            PhaseDefinition(
                title: "Optimization: Maximizing \(topic)",
                description: "Fine-tune and optimize your approach to \(topic)",
                taskTypes: [.review, .optimization, .planning, .celebration]
            )
        ]
        return Array(allPhases.prefix(count))
    }

    private func getCreativityPhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Inspiration: Exploring \(topic)",
                description: "Gather inspiration and learn techniques for \(topic)",
                taskTypes: [.research, .exploration, .practice, .ideation]
            ),
            PhaseDefinition(
                title: "Creation: Developing \(topic)",
                description: "Create and experiment with \(topic)",
                taskTypes: [.creation, .practice, .experimentation, .review]
            ),
            PhaseDefinition(
                title: "Refinement: Perfecting \(topic)",
                description: "Refine and polish your \(topic) work",
                taskTypes: [.refinement, .feedback, .practice, .creation]
            ),
            PhaseDefinition(
                title: "Sharing: Presenting \(topic)",
                description: "Share and celebrate your \(topic) achievements",
                taskTypes: [.preparation, .sharing, .celebration, .planning]
            )
        ]
        return Array(allPhases.prefix(count))
    }

    private func getRelationshipsPhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Reflection: Understanding \(topic)",
                description: "Reflect on your goals for \(topic)",
                taskTypes: [.reflection, .planning, .communication, .quality_time]
            ),
            PhaseDefinition(
                title: "Connection: Building \(topic)",
                description: "Take action to strengthen \(topic)",
                taskTypes: [.quality_time, .communication, .planning, .reflection]
            ),
            PhaseDefinition(
                title: "Deepening: Strengthening \(topic)",
                description: "Deepen your connections in \(topic)",
                taskTypes: [.quality_time, .activity, .communication, .reflection]
            ),
            PhaseDefinition(
                title: "Growth: Nurturing \(topic)",
                description: "Continue growing and nurturing \(topic)",
                taskTypes: [.activity, .quality_time, .celebration, .planning]
            )
        ]
        return Array(allPhases.prefix(count))
    }

    private func getPersonalPhases(topic: String, count: Int) -> [PhaseDefinition] {
        let allPhases = [
            PhaseDefinition(
                title: "Discovery: Exploring \(topic)",
                description: "Understand what \(topic) means for you",
                taskTypes: [.reflection, .research, .planning, .journaling]
            ),
            PhaseDefinition(
                title: "Development: Working on \(topic)",
                description: "Take action toward \(topic)",
                taskTypes: [.action, .practice, .review, .journaling]
            ),
            PhaseDefinition(
                title: "Growth: Advancing \(topic)",
                description: "Push further with \(topic)",
                taskTypes: [.action, .practice, .reflection, .adjustment]
            ),
            PhaseDefinition(
                title: "Integration: Living \(topic)",
                description: "Make \(topic) part of who you are",
                taskTypes: [.practice, .celebration, .planning, .reflection]
            )
        ]
        return Array(allPhases.prefix(count))
    }
}

// MARK: - Supporting Types

private struct PhaseDefinition {
    let title: String
    let description: String
    let taskTypes: [TaskType]

    func getTaskTemplates(topic: String, category: GoalCategory) -> [TaskDefinition] {
        return taskTypes.flatMap { type in
            type.getTasksForTopic(topic, category: category)
        }
    }
}

private struct TaskDefinition {
    let title: String
    let description: String?
    let duration: Int
    let resources: [String]?

    init(_ title: String, description: String? = nil, duration: Int = 45, resources: [String]? = nil) {
        self.title = title
        self.description = description
        self.duration = duration
        self.resources = resources
    }
}

private enum TaskType {
    // Education
    case research, study, practice, review, advancedStudy, project, teach

    // Fitness
    case assessment, lightActivity, planning, tracking, workout, recovery, intenseWorkout, celebration

    // Career
    case networking, skillAssessment, skillBuilding, preparation, application, followUp, interview, negotiation

    // Health
    case healthActivity, adjustment, maintenance

    // Finance
    case setup, action, optimization

    // Creativity
    case exploration, ideation, creation, experimentation, refinement, feedback, sharing

    // Relationships
    case reflection, communication, quality_time, activity

    // Personal
    case journaling

    func getTasksForTopic(_ topic: String, category: GoalCategory) -> [TaskDefinition] {
        switch self {
        // Education tasks
        case .research:
            return [
                TaskDefinition("Research \(topic) fundamentals", duration: 45),
                TaskDefinition("Find resources for learning \(topic)", duration: 30),
                TaskDefinition("Watch introductory video on \(topic)", duration: 40)
            ]
        case .study:
            return [
                TaskDefinition("Study \(topic) concepts", duration: 60),
                TaskDefinition("Read chapter about \(topic)", duration: 45),
                TaskDefinition("Take notes on \(topic)", duration: 30)
            ]
        case .practice:
            return [
                TaskDefinition("Practice \(topic) exercises", duration: 45),
                TaskDefinition("Complete \(topic) practice problems", duration: 50),
                TaskDefinition("Apply \(topic) to example scenarios", duration: 40)
            ]
        case .review:
            return [
                TaskDefinition("Review \(topic) material", duration: 30),
                TaskDefinition("Create flashcards for \(topic)", duration: 25),
                TaskDefinition("Quiz yourself on \(topic)", duration: 20)
            ]
        case .advancedStudy:
            return [
                TaskDefinition("Study advanced \(topic) concepts", duration: 75),
                TaskDefinition("Deep dive into \(topic) techniques", duration: 60)
            ]
        case .project:
            return [
                TaskDefinition("Work on \(topic) project", duration: 90),
                TaskDefinition("Build something using \(topic)", duration: 60),
                TaskDefinition("Create \(topic) portfolio piece", duration: 75)
            ]
        case .teach:
            return [
                TaskDefinition("Explain \(topic) concepts (teach to learn)", duration: 30),
                TaskDefinition("Write summary of \(topic) learnings", duration: 40)
            ]

        // Fitness tasks
        case .assessment:
            return [
                TaskDefinition("Assess current fitness level for \(topic)", duration: 30),
                TaskDefinition("Set baseline measurements for \(topic)", duration: 20)
            ]
        case .lightActivity:
            return [
                TaskDefinition("Light \(topic) session", duration: 30),
                TaskDefinition("Beginner \(topic) workout", duration: 25),
                TaskDefinition("Warm-up and stretching for \(topic)", duration: 20)
            ]
        case .workout:
            return [
                TaskDefinition("\(topic) training session", duration: 45),
                TaskDefinition("Complete \(topic) workout routine", duration: 50),
                TaskDefinition("\(topic) exercise circuit", duration: 40)
            ]
        case .intenseWorkout:
            return [
                TaskDefinition("High-intensity \(topic) workout", duration: 45),
                TaskDefinition("Challenging \(topic) session", duration: 50),
                TaskDefinition("Push your \(topic) limits", duration: 40)
            ]
        case .recovery:
            return [
                TaskDefinition("Recovery and stretching for \(topic)", duration: 20),
                TaskDefinition("Rest day - light mobility for \(topic)", duration: 15)
            ]
        case .tracking:
            return [
                TaskDefinition("Log \(topic) progress", duration: 10),
                TaskDefinition("Track \(topic) metrics", duration: 15)
            ]

        // Career tasks
        case .networking:
            return [
                TaskDefinition("Network with \(topic) professionals", duration: 45),
                TaskDefinition("Reach out to \(topic) contacts", duration: 30),
                TaskDefinition("Attend \(topic) networking event", duration: 60)
            ]
        case .skillAssessment:
            return [
                TaskDefinition("Assess skills needed for \(topic)", duration: 40),
                TaskDefinition("Identify gaps for \(topic)", duration: 30)
            ]
        case .skillBuilding:
            return [
                TaskDefinition("Build skills for \(topic)", duration: 60),
                TaskDefinition("Practice \(topic) skills", duration: 45),
                TaskDefinition("Take course on \(topic)", duration: 50)
            ]
        case .preparation:
            return [
                TaskDefinition("Prepare materials for \(topic)", duration: 60),
                TaskDefinition("Update resume for \(topic)", duration: 45),
                TaskDefinition("Prepare portfolio for \(topic)", duration: 50)
            ]
        case .application:
            return [
                TaskDefinition("Apply for \(topic) opportunities", duration: 45),
                TaskDefinition("Submit \(topic) applications", duration: 40)
            ]
        case .followUp:
            return [
                TaskDefinition("Follow up on \(topic) applications", duration: 25),
                TaskDefinition("Send thank-you notes for \(topic)", duration: 15)
            ]
        case .interview:
            return [
                TaskDefinition("Practice \(topic) interview questions", duration: 45),
                TaskDefinition("Mock interview for \(topic)", duration: 60)
            ]
        case .negotiation:
            return [
                TaskDefinition("Research \(topic) compensation", duration: 40),
                TaskDefinition("Prepare negotiation points for \(topic)", duration: 30)
            ]

        // Planning (shared)
        case .planning:
            return [
                TaskDefinition("Plan next steps for \(topic)", duration: 30),
                TaskDefinition("Set weekly goals for \(topic)", duration: 20)
            ]

        // Celebration (shared)
        case .celebration:
            return [
                TaskDefinition("Celebrate \(topic) progress", duration: 20),
                TaskDefinition("Reflect on \(topic) achievements", duration: 25)
            ]

        // Health tasks
        case .healthActivity:
            return [
                TaskDefinition("\(topic) activity session", duration: 30),
                TaskDefinition("Practice \(topic)", duration: 25),
                TaskDefinition("Work on \(topic) habits", duration: 20)
            ]
        case .adjustment:
            return [
                TaskDefinition("Adjust \(topic) approach as needed", duration: 20)
            ]
        case .maintenance:
            return [
                TaskDefinition("Maintain \(topic) routine", duration: 25)
            ]

        // Finance tasks
        case .setup:
            return [
                TaskDefinition("Set up systems for \(topic)", duration: 45),
                TaskDefinition("Configure tools for \(topic)", duration: 30)
            ]
        case .action:
            return [
                TaskDefinition("Take action on \(topic)", duration: 30),
                TaskDefinition("Execute \(topic) plan", duration: 25)
            ]
        case .optimization:
            return [
                TaskDefinition("Optimize \(topic) strategy", duration: 35),
                TaskDefinition("Find ways to improve \(topic)", duration: 30)
            ]

        // Creativity tasks
        case .exploration:
            return [
                TaskDefinition("Explore \(topic) techniques", duration: 45),
                TaskDefinition("Experiment with \(topic) styles", duration: 40)
            ]
        case .ideation:
            return [
                TaskDefinition("Brainstorm ideas for \(topic)", duration: 30),
                TaskDefinition("Sketch concepts for \(topic)", duration: 35)
            ]
        case .creation:
            return [
                TaskDefinition("Create \(topic) work", duration: 60),
                TaskDefinition("Work on \(topic) piece", duration: 75),
                TaskDefinition("Develop \(topic) project", duration: 50)
            ]
        case .experimentation:
            return [
                TaskDefinition("Try new \(topic) approaches", duration: 45)
            ]
        case .refinement:
            return [
                TaskDefinition("Refine \(topic) work", duration: 45),
                TaskDefinition("Polish \(topic) piece", duration: 40)
            ]
        case .feedback:
            return [
                TaskDefinition("Get feedback on \(topic)", duration: 30),
                TaskDefinition("Review \(topic) with others", duration: 35)
            ]
        case .sharing:
            return [
                TaskDefinition("Share \(topic) with others", duration: 30),
                TaskDefinition("Present \(topic) work", duration: 45)
            ]

        // Relationship tasks
        case .reflection:
            return [
                TaskDefinition("Reflect on \(topic) goals", duration: 25),
                TaskDefinition("Journal about \(topic)", duration: 20)
            ]
        case .communication:
            return [
                TaskDefinition("Have meaningful conversation about \(topic)", duration: 40),
                TaskDefinition("Express feelings about \(topic)", duration: 25)
            ]
        case .quality_time:
            return [
                TaskDefinition("Quality time focused on \(topic)", duration: 60),
                TaskDefinition("Dedicated time for \(topic)", duration: 45)
            ]
        case .activity:
            return [
                TaskDefinition("Do \(topic) activity together", duration: 60),
                TaskDefinition("Plan special \(topic) experience", duration: 45)
            ]

        // Personal tasks
        case .journaling:
            return [
                TaskDefinition("Journal about \(topic) progress", duration: 20),
                TaskDefinition("Write reflections on \(topic)", duration: 25)
            ]
        }
    }
}
