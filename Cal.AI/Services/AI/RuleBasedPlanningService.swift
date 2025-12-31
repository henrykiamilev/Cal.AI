import Foundation

/// Rule-based planning service that generates goal schedules using templates and algorithms
/// Works entirely on-device without requiring any external API
final class RuleBasedPlanningService: AIServiceProtocol {

    // MARK: - Generate Goal Plan
    func generateGoalPlan(
        goal: Goal,
        userProfile: UserProfile,
        existingCommitments: [Event]
    ) async throws -> AISchedule {
        let template = getTemplate(for: goal.category, goalTitle: goal.title)
        let availableHoursPerWeek = userProfile.weeklyAvailableHours

        // Calculate duration based on target date or estimate
        let targetDate = goal.targetDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date())!
        let totalDays = max(7, Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 90)
        let totalWeeks = max(1, totalDays / 7)

        // Generate phases based on template
        let phases = generatePhases(
            template: template,
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
                // Find the phase containing this task
                for phaseIndex in adjustedSchedule.phases.indices {
                    if let taskIndex = adjustedSchedule.phases[phaseIndex].tasks.firstIndex(where: { $0.id == missedTask.id }) {
                        // Reschedule to next available day
                        nextAvailableDate = Calendar.current.date(byAdding: .day, value: 1, to: nextAvailableDate) ?? nextAvailableDate
                        adjustedSchedule.phases[phaseIndex].tasks[taskIndex].scheduledDate = nextAvailableDate
                    }
                }
            }

            // Add adjustment record
            adjustedSchedule.addAdjustment(AISchedule.Adjustment(
                reason: .missedTasks,
                description: "Rescheduled \(missedTasks.count) missed task(s)",
                changes: "Tasks moved to upcoming days"
            ))
        }

        // If ahead of schedule, potentially compress remaining tasks
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

        // Calculate score (0-100)
        var score: Double = progress * 100

        // Penalize for overdue tasks
        if totalCount > 0 {
            let overdueRatio = Double(overdueCount) / Double(totalCount)
            score -= overdueRatio * 30
        }

        // Bonus for being ahead
        if progress > expectedProgress {
            score += 10
        }

        score = max(0, min(100, score))

        // Generate insights
        var strengths: [String] = []
        var improvements: [String] = []
        var recommendations: [String] = []

        if progress >= expectedProgress {
            strengths.append("You're on track with your goal")
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
            strengths.append("Starting your journey toward this goal")
        }

        if recommendations.isEmpty {
            recommendations.append("Keep up the consistent effort")
            recommendations.append("Review upcoming tasks at the start of each week")
        }

        // Estimate new completion date based on current pace
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

        let overdueTasks = schedule.overdueTasks
        let todayTasks = schedule.tasksForToday
        let progress = schedule.overallProgress

        if !overdueTasks.isEmpty {
            suggestions.append("You have \(overdueTasks.count) overdue task(s). Try to complete them today.")
        }

        if todayTasks.isEmpty && !schedule.upcomingTasks.isEmpty {
            suggestions.append("No tasks scheduled for today. Consider working ahead on upcoming tasks.")
        }

        if progress < 0.25 && schedule.totalTasks > 0 {
            suggestions.append("You're in the early stages. Building momentum is key!")
        } else if progress >= 0.75 {
            suggestions.append("You're in the home stretch! Stay focused to finish strong.")
        }

        // Category-specific suggestions
        switch goal.category {
        case .fitness:
            suggestions.append("Remember to stay hydrated and get adequate rest between workouts.")
        case .education:
            suggestions.append("Try the Pomodoro technique: 25 minutes of focused study, then a 5-minute break.")
        case .career:
            suggestions.append("Network with professionals in your target field for insights and opportunities.")
        case .health:
            suggestions.append("Track your progress in a journal to stay motivated.")
        case .finance:
            suggestions.append("Review your spending weekly to stay on track with financial goals.")
        case .creativity:
            suggestions.append("Set aside dedicated creative time without distractions.")
        case .relationships:
            suggestions.append("Quality time matters more than quantity. Be present in your interactions.")
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

    private func generatePhases(
        template: GoalTemplate,
        totalWeeks: Int,
        hoursPerWeek: Double,
        startDate: Date,
        existingCommitments: [Event]
    ) -> [AISchedule.Phase] {
        var phases: [AISchedule.Phase] = []
        let calendar = Calendar.current

        let weeksPerPhase = max(1, totalWeeks / template.phases.count)
        var currentDate = startDate

        for (index, phaseTemplate) in template.phases.enumerated() {
            let phaseStartDate = currentDate
            let phaseEndDate = calendar.date(byAdding: .weekOfYear, value: weeksPerPhase, to: phaseStartDate) ?? phaseStartDate

            // Generate tasks for this phase
            let tasks = generateTasks(
                for: phaseTemplate,
                startDate: phaseStartDate,
                endDate: phaseEndDate,
                hoursPerWeek: hoursPerWeek,
                existingCommitments: existingCommitments
            )

            let phase = AISchedule.Phase(
                title: phaseTemplate.title,
                description: phaseTemplate.description,
                startDate: phaseStartDate,
                endDate: phaseEndDate,
                tasks: tasks
            )

            phases.append(phase)
            currentDate = calendar.date(byAdding: .day, value: 1, to: phaseEndDate) ?? phaseEndDate
        }

        return phases
    }

    private func generateTasks(
        for phaseTemplate: PhaseTemplate,
        startDate: Date,
        endDate: Date,
        hoursPerWeek: Double,
        existingCommitments: [Event]
    ) -> [AISchedule.ScheduledTask] {
        var tasks: [AISchedule.ScheduledTask] = []
        let calendar = Calendar.current

        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7
        let tasksPerWeek = Int(hoursPerWeek / 1.5) // Assume ~1.5 hours per task average
        let totalTasks = max(phaseTemplate.taskTemplates.count, (totalDays / 7) * max(1, tasksPerWeek))

        var currentDate = startDate
        var taskIndex = 0

        for i in 0..<totalTasks {
            // Get task template (cycle through if needed)
            let templateIndex = i % phaseTemplate.taskTemplates.count
            let taskTemplate = phaseTemplate.taskTemplates[templateIndex]

            // Skip weekends if possible
            while calendar.isDateInWeekend(currentDate) && currentDate < endDate {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            // Check for conflicts with existing events
            let hasConflict = existingCommitments.contains { event in
                event.startDate.isSameDay(as: currentDate)
            }

            if hasConflict {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            guard currentDate <= endDate else { break }

            let task = AISchedule.ScheduledTask(
                title: taskTemplate.title,
                description: taskTemplate.description,
                scheduledDate: currentDate,
                durationMinutes: taskTemplate.durationMinutes,
                resources: taskTemplate.resources
            )

            tasks.append(task)
            taskIndex += 1

            // Move to next day or skip a day based on frequency
            let daysToAdd = max(1, 7 / max(1, tasksPerWeek))
            currentDate = calendar.date(byAdding: .day, value: daysToAdd, to: currentDate) ?? currentDate
        }

        return tasks
    }

    // MARK: - Templates

    private func getTemplate(for category: GoalCategory, goalTitle: String) -> GoalTemplate {
        let titleLower = goalTitle.lowercased()

        // Check for specific goal patterns first
        if titleLower.contains("weight") || titleLower.contains("lose") || titleLower.contains("fit") {
            return fitnessWeightLossTemplate
        }
        if titleLower.contains("learn") || titleLower.contains("study") || titleLower.contains("course") {
            return educationLearningTemplate
        }
        if titleLower.contains("job") || titleLower.contains("career") || titleLower.contains("promotion") || titleLower.contains("interview") {
            return careerJobSearchTemplate
        }
        if titleLower.contains("save") || titleLower.contains("money") || titleLower.contains("budget") {
            return financeSavingsTemplate
        }
        if titleLower.contains("read") || titleLower.contains("book") {
            return personalReadingTemplate
        }
        if titleLower.contains("meditat") || titleLower.contains("mindful") || titleLower.contains("stress") {
            return healthMindfulnessTemplate
        }

        // Fall back to category-based templates
        switch category {
        case .fitness:
            return fitnessGeneralTemplate
        case .education:
            return educationLearningTemplate
        case .career:
            return careerGeneralTemplate
        case .health:
            return healthGeneralTemplate
        case .finance:
            return financeSavingsTemplate
        case .creativity:
            return creativityTemplate
        case .relationships:
            return relationshipsTemplate
        case .personal:
            return personalGrowthTemplate
        }
    }
}

// MARK: - Template Structures

struct GoalTemplate {
    let phases: [PhaseTemplate]
}

struct PhaseTemplate {
    let title: String
    let description: String
    let taskTemplates: [TaskTemplate]
}

struct TaskTemplate {
    let title: String
    let description: String?
    let durationMinutes: Int
    let resources: [String]?

    init(title: String, description: String? = nil, durationMinutes: Int = 60, resources: [String]? = nil) {
        self.title = title
        self.description = description
        self.durationMinutes = durationMinutes
        self.resources = resources
    }
}

// MARK: - Predefined Templates

private let fitnessWeightLossTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Foundation & Assessment",
        description: "Establish baseline habits and assess current fitness level",
        taskTemplates: [
            TaskTemplate(title: "Take body measurements and photos", durationMinutes: 30),
            TaskTemplate(title: "Plan weekly meal prep", durationMinutes: 45),
            TaskTemplate(title: "30-minute walk or light cardio", durationMinutes: 30),
            TaskTemplate(title: "Research healthy recipes", durationMinutes: 30),
            TaskTemplate(title: "Set up meal tracking app", durationMinutes: 20)
        ]
    ),
    PhaseTemplate(
        title: "Building Momentum",
        description: "Increase activity level and establish consistent habits",
        taskTemplates: [
            TaskTemplate(title: "45-minute cardio session", durationMinutes: 45),
            TaskTemplate(title: "Strength training workout", durationMinutes: 45),
            TaskTemplate(title: "Meal prep for the week", durationMinutes: 90),
            TaskTemplate(title: "30-minute active recovery (yoga/stretching)", durationMinutes: 30),
            TaskTemplate(title: "Review and log weekly progress", durationMinutes: 20)
        ]
    ),
    PhaseTemplate(
        title: "Intensification",
        description: "Push harder and refine your approach",
        taskTemplates: [
            TaskTemplate(title: "High-intensity interval training (HIIT)", durationMinutes: 40),
            TaskTemplate(title: "Full body strength workout", durationMinutes: 60),
            TaskTemplate(title: "Active cardio session", durationMinutes: 45),
            TaskTemplate(title: "Flexibility and mobility work", durationMinutes: 30),
            TaskTemplate(title: "Weekly weigh-in and measurements", durationMinutes: 15)
        ]
    ),
    PhaseTemplate(
        title: "Maintenance & Lifestyle",
        description: "Transition to sustainable long-term habits",
        taskTemplates: [
            TaskTemplate(title: "Workout session (your choice)", durationMinutes: 60),
            TaskTemplate(title: "Plan next week's activities", durationMinutes: 30),
            TaskTemplate(title: "Try a new healthy recipe", durationMinutes: 60),
            TaskTemplate(title: "Active outdoor activity", durationMinutes: 60),
            TaskTemplate(title: "Reflect on progress and set new mini-goals", durationMinutes: 30)
        ]
    )
])

private let fitnessGeneralTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Getting Started",
        description: "Build foundational fitness habits",
        taskTemplates: [
            TaskTemplate(title: "Light cardio session", durationMinutes: 30),
            TaskTemplate(title: "Basic strength exercises", durationMinutes: 30),
            TaskTemplate(title: "Stretching routine", durationMinutes: 20),
            TaskTemplate(title: "Plan workout schedule", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Building Strength",
        description: "Increase workout intensity",
        taskTemplates: [
            TaskTemplate(title: "Cardio workout", durationMinutes: 45),
            TaskTemplate(title: "Strength training", durationMinutes: 45),
            TaskTemplate(title: "Core workout", durationMinutes: 30),
            TaskTemplate(title: "Recovery stretching", durationMinutes: 20)
        ]
    ),
    PhaseTemplate(
        title: "Advanced Training",
        description: "Push your limits",
        taskTemplates: [
            TaskTemplate(title: "Intense cardio session", durationMinutes: 50),
            TaskTemplate(title: "Heavy strength training", durationMinutes: 60),
            TaskTemplate(title: "Flexibility work", durationMinutes: 30)
        ]
    )
])

private let educationLearningTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Foundation",
        description: "Learn core concepts and fundamentals",
        taskTemplates: [
            TaskTemplate(title: "Study fundamental concepts", durationMinutes: 60),
            TaskTemplate(title: "Take notes and summarize", durationMinutes: 30),
            TaskTemplate(title: "Practice exercises", durationMinutes: 45),
            TaskTemplate(title: "Watch tutorial/lecture", durationMinutes: 45),
            TaskTemplate(title: "Review and self-test", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Deep Learning",
        description: "Dive deeper into complex topics",
        taskTemplates: [
            TaskTemplate(title: "Study advanced material", durationMinutes: 90),
            TaskTemplate(title: "Work on practice problems", durationMinutes: 60),
            TaskTemplate(title: "Create flashcards for review", durationMinutes: 30),
            TaskTemplate(title: "Apply concepts to project", durationMinutes: 60)
        ]
    ),
    PhaseTemplate(
        title: "Application & Mastery",
        description: "Apply knowledge and solidify understanding",
        taskTemplates: [
            TaskTemplate(title: "Work on capstone project", durationMinutes: 90),
            TaskTemplate(title: "Review all material", durationMinutes: 60),
            TaskTemplate(title: "Practice teaching concepts", durationMinutes: 45),
            TaskTemplate(title: "Take practice assessment", durationMinutes: 60)
        ]
    )
])

private let careerJobSearchTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Preparation",
        description: "Update materials and research opportunities",
        taskTemplates: [
            TaskTemplate(title: "Update resume", durationMinutes: 90),
            TaskTemplate(title: "Optimize LinkedIn profile", durationMinutes: 60),
            TaskTemplate(title: "Research target companies", durationMinutes: 60),
            TaskTemplate(title: "Identify key skills to highlight", durationMinutes: 45),
            TaskTemplate(title: "Prepare portfolio/work samples", durationMinutes: 90)
        ]
    ),
    PhaseTemplate(
        title: "Active Search",
        description: "Apply and network actively",
        taskTemplates: [
            TaskTemplate(title: "Apply to job postings", durationMinutes: 60),
            TaskTemplate(title: "Networking outreach", durationMinutes: 45),
            TaskTemplate(title: "Practice interview questions", durationMinutes: 45),
            TaskTemplate(title: "Follow up on applications", durationMinutes: 30),
            TaskTemplate(title: "Attend networking event or webinar", durationMinutes: 90)
        ]
    ),
    PhaseTemplate(
        title: "Interview Preparation",
        description: "Prepare for and ace interviews",
        taskTemplates: [
            TaskTemplate(title: "Research company culture", durationMinutes: 45),
            TaskTemplate(title: "Practice behavioral questions", durationMinutes: 60),
            TaskTemplate(title: "Prepare questions for interviewer", durationMinutes: 30),
            TaskTemplate(title: "Mock interview session", durationMinutes: 60),
            TaskTemplate(title: "Review and refine pitch", durationMinutes: 30)
        ]
    )
])

private let careerGeneralTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Assessment",
        description: "Evaluate current position and goals",
        taskTemplates: [
            TaskTemplate(title: "Define career objectives", durationMinutes: 60),
            TaskTemplate(title: "Identify skill gaps", durationMinutes: 45),
            TaskTemplate(title: "Research industry trends", durationMinutes: 60)
        ]
    ),
    PhaseTemplate(
        title: "Skill Building",
        description: "Develop necessary skills",
        taskTemplates: [
            TaskTemplate(title: "Take online course/training", durationMinutes: 90),
            TaskTemplate(title: "Practice new skills", durationMinutes: 60),
            TaskTemplate(title: "Seek feedback from mentor", durationMinutes: 45)
        ]
    ),
    PhaseTemplate(
        title: "Advancement",
        description: "Take action toward goals",
        taskTemplates: [
            TaskTemplate(title: "Work on visibility project", durationMinutes: 90),
            TaskTemplate(title: "Network with leaders", durationMinutes: 60),
            TaskTemplate(title: "Document achievements", durationMinutes: 45)
        ]
    )
])

private let financeSavingsTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Assessment",
        description: "Understand your current financial situation",
        taskTemplates: [
            TaskTemplate(title: "Track all expenses for a week", durationMinutes: 30),
            TaskTemplate(title: "Review bank statements", durationMinutes: 45),
            TaskTemplate(title: "Calculate net worth", durationMinutes: 30),
            TaskTemplate(title: "Identify unnecessary subscriptions", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Planning",
        description: "Create a savings strategy",
        taskTemplates: [
            TaskTemplate(title: "Create monthly budget", durationMinutes: 60),
            TaskTemplate(title: "Set up automatic savings", durationMinutes: 30),
            TaskTemplate(title: "Research high-yield savings accounts", durationMinutes: 45),
            TaskTemplate(title: "Plan for upcoming expenses", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Execution",
        description: "Implement and monitor your plan",
        taskTemplates: [
            TaskTemplate(title: "Weekly budget review", durationMinutes: 20),
            TaskTemplate(title: "Find ways to reduce expenses", durationMinutes: 30),
            TaskTemplate(title: "Review savings progress", durationMinutes: 20),
            TaskTemplate(title: "Adjust budget as needed", durationMinutes: 30)
        ]
    )
])

private let healthGeneralTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Awareness",
        description: "Understand your health baseline",
        taskTemplates: [
            TaskTemplate(title: "Schedule health checkup", durationMinutes: 30),
            TaskTemplate(title: "Start health journal", durationMinutes: 30),
            TaskTemplate(title: "Research health best practices", durationMinutes: 45)
        ]
    ),
    PhaseTemplate(
        title: "Habit Formation",
        description: "Build healthy habits",
        taskTemplates: [
            TaskTemplate(title: "Morning wellness routine", durationMinutes: 30),
            TaskTemplate(title: "Healthy meal preparation", durationMinutes: 60),
            TaskTemplate(title: "Evening wind-down routine", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Optimization",
        description: "Fine-tune your health practices",
        taskTemplates: [
            TaskTemplate(title: "Review and adjust routines", durationMinutes: 30),
            TaskTemplate(title: "Try new healthy activity", durationMinutes: 45),
            TaskTemplate(title: "Track health metrics", durationMinutes: 20)
        ]
    )
])

private let healthMindfulnessTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Introduction",
        description: "Learn meditation basics",
        taskTemplates: [
            TaskTemplate(title: "5-minute guided meditation", durationMinutes: 10),
            TaskTemplate(title: "Deep breathing exercises", durationMinutes: 10),
            TaskTemplate(title: "Journaling practice", durationMinutes: 20),
            TaskTemplate(title: "Learn about mindfulness", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Building Practice",
        description: "Establish regular meditation habit",
        taskTemplates: [
            TaskTemplate(title: "10-minute meditation", durationMinutes: 15),
            TaskTemplate(title: "Mindful walking", durationMinutes: 20),
            TaskTemplate(title: "Gratitude journaling", durationMinutes: 15),
            TaskTemplate(title: "Body scan meditation", durationMinutes: 20)
        ]
    ),
    PhaseTemplate(
        title: "Deepening Practice",
        description: "Extend and deepen your practice",
        taskTemplates: [
            TaskTemplate(title: "20-minute meditation", durationMinutes: 25),
            TaskTemplate(title: "Mindfulness in daily activities", durationMinutes: 30),
            TaskTemplate(title: "Loving-kindness meditation", durationMinutes: 20),
            TaskTemplate(title: "Weekly reflection", durationMinutes: 30)
        ]
    )
])

private let creativityTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Exploration",
        description: "Explore and gather inspiration",
        taskTemplates: [
            TaskTemplate(title: "Research and gather inspiration", durationMinutes: 45),
            TaskTemplate(title: "Experiment with techniques", durationMinutes: 60),
            TaskTemplate(title: "Create rough sketches/drafts", durationMinutes: 45)
        ]
    ),
    PhaseTemplate(
        title: "Development",
        description: "Develop your creative skills",
        taskTemplates: [
            TaskTemplate(title: "Focused creative practice", durationMinutes: 90),
            TaskTemplate(title: "Learn new technique", durationMinutes: 60),
            TaskTemplate(title: "Work on project", durationMinutes: 90)
        ]
    ),
    PhaseTemplate(
        title: "Refinement",
        description: "Polish and share your work",
        taskTemplates: [
            TaskTemplate(title: "Refine and edit work", durationMinutes: 60),
            TaskTemplate(title: "Get feedback", durationMinutes: 45),
            TaskTemplate(title: "Prepare for sharing/exhibition", durationMinutes: 60)
        ]
    )
])

private let relationshipsTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Reflection",
        description: "Understand your relationship goals",
        taskTemplates: [
            TaskTemplate(title: "Reflect on relationship values", durationMinutes: 30),
            TaskTemplate(title: "Identify areas for improvement", durationMinutes: 30),
            TaskTemplate(title: "Plan quality time activities", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Connection",
        description: "Build deeper connections",
        taskTemplates: [
            TaskTemplate(title: "Quality time with loved one", durationMinutes: 60),
            TaskTemplate(title: "Practice active listening", durationMinutes: 30),
            TaskTemplate(title: "Express appreciation", durationMinutes: 20),
            TaskTemplate(title: "Plan meaningful activity", durationMinutes: 45)
        ]
    ),
    PhaseTemplate(
        title: "Growth",
        description: "Strengthen and grow together",
        taskTemplates: [
            TaskTemplate(title: "Have meaningful conversation", durationMinutes: 45),
            TaskTemplate(title: "Try new activity together", durationMinutes: 90),
            TaskTemplate(title: "Reflect on relationship progress", durationMinutes: 30)
        ]
    )
])

private let personalGrowthTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Self-Discovery",
        description: "Understand yourself better",
        taskTemplates: [
            TaskTemplate(title: "Journaling session", durationMinutes: 30),
            TaskTemplate(title: "Identify values and priorities", durationMinutes: 45),
            TaskTemplate(title: "Set specific objectives", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Development",
        description: "Work on personal development",
        taskTemplates: [
            TaskTemplate(title: "Read personal development content", durationMinutes: 45),
            TaskTemplate(title: "Practice new habit", durationMinutes: 30),
            TaskTemplate(title: "Reflect on progress", durationMinutes: 20)
        ]
    ),
    PhaseTemplate(
        title: "Integration",
        description: "Integrate changes into daily life",
        taskTemplates: [
            TaskTemplate(title: "Review and adjust goals", durationMinutes: 30),
            TaskTemplate(title: "Celebrate progress", durationMinutes: 20),
            TaskTemplate(title: "Plan next steps", durationMinutes: 30)
        ]
    )
])

private let personalReadingTemplate = GoalTemplate(phases: [
    PhaseTemplate(
        title: "Setup",
        description: "Establish your reading habit",
        taskTemplates: [
            TaskTemplate(title: "Create reading list", durationMinutes: 30),
            TaskTemplate(title: "Set up reading space", durationMinutes: 20),
            TaskTemplate(title: "Schedule daily reading time", durationMinutes: 15),
            TaskTemplate(title: "Read for 20 minutes", durationMinutes: 25)
        ]
    ),
    PhaseTemplate(
        title: "Building Momentum",
        description: "Increase reading consistency",
        taskTemplates: [
            TaskTemplate(title: "30-minute reading session", durationMinutes: 35),
            TaskTemplate(title: "Take notes on key insights", durationMinutes: 20),
            TaskTemplate(title: "Discuss book with others", durationMinutes: 30)
        ]
    ),
    PhaseTemplate(
        title: "Deep Reading",
        description: "Engage more deeply with content",
        taskTemplates: [
            TaskTemplate(title: "Extended reading session", durationMinutes: 60),
            TaskTemplate(title: "Write book summary", durationMinutes: 30),
            TaskTemplate(title: "Apply insights to life", durationMinutes: 30)
        ]
    )
])
