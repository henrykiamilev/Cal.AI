import Foundation

/// OpenAI API implementation for AI-powered goal planning
final class OpenAIService: AIServiceProtocol {
    private let session: URLSession
    private var apiKey: String {
        AppConfiguration.openAIKey
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Generate Goal Plan
    func generateGoalPlan(
        goal: Goal,
        userProfile: UserProfile,
        existingCommitments: [Event]
    ) async throws -> AISchedule {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        let prompt = buildPlanningPrompt(goal: goal, profile: userProfile, commitments: existingCommitments)
        let response = try await sendChatCompletion(
            systemPrompt: SystemPrompts.goalPlanner,
            userPrompt: prompt
        )

        return try parseGoalPlanResponse(response, goal: goal, profile: userProfile)
    }

    // MARK: - Adjust Schedule
    func adjustSchedule(
        currentSchedule: AISchedule,
        goal: Goal,
        completedTasks: [AISchedule.ScheduledTask],
        missedTasks: [AISchedule.ScheduledTask]
    ) async throws -> AISchedule {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        let prompt = buildAdjustmentPrompt(
            schedule: currentSchedule,
            goal: goal,
            completed: completedTasks,
            missed: missedTasks
        )

        let response = try await sendChatCompletion(
            systemPrompt: SystemPrompts.scheduleAdjuster,
            userPrompt: prompt
        )

        var updatedSchedule = try parseAdjustmentResponse(response, currentSchedule: currentSchedule)

        // Add adjustment record
        let adjustment = AISchedule.Adjustment(
            reason: missedTasks.isEmpty ? .aheadOfSchedule : .missedTasks,
            description: "Schedule adjusted based on progress",
            changes: "Updated \(missedTasks.count) missed tasks, \(completedTasks.count) completed"
        )
        updatedSchedule.addAdjustment(adjustment)

        return updatedSchedule
    }

    // MARK: - Analyze Progress
    func analyzeProgress(
        goal: Goal,
        schedule: AISchedule
    ) async throws -> ProgressAnalysis {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        let prompt = buildProgressAnalysisPrompt(goal: goal, schedule: schedule)
        let response = try await sendChatCompletion(
            systemPrompt: SystemPrompts.progressAnalyzer,
            userPrompt: prompt
        )

        return try parseProgressAnalysisResponse(response)
    }

    // MARK: - Get Suggestions
    func getSuggestions(
        goal: Goal,
        schedule: AISchedule,
        userProfile: UserProfile
    ) async throws -> [String] {
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }

        let prompt = buildSuggestionsPrompt(goal: goal, schedule: schedule, profile: userProfile)
        let response = try await sendChatCompletion(
            systemPrompt: SystemPrompts.suggestionGenerator,
            userPrompt: prompt
        )

        return parseSuggestionsResponse(response)
    }

    // MARK: - API Communication
    private func sendChatCompletion(
        systemPrompt: String,
        userPrompt: String
    ) async throws -> String {
        let url = URL(string: AppConfiguration.Endpoints.chatCompletions)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages = [
            AIMessage(role: "system", content: systemPrompt),
            AIMessage(role: "user", content: userPrompt)
        ]

        let body = AICompletionRequest(
            model: AppConfiguration.openAIModel,
            messages: messages,
            temperature: 0.7,
            maxTokens: 4000,
            responseFormat: AICompletionRequest.ResponseFormat(type: "json_object")
        )

        request.httpBody = try JSONEncoder().encode(body)

        if AppConfiguration.shouldLogNetworkRequests {
            print("📤 AI Request: \(userPrompt.prefix(200))...")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            throw AIServiceError.rateLimited
        case 500...599:
            throw AIServiceError.serverError(httpResponse.statusCode)
        default:
            throw AIServiceError.serverError(httpResponse.statusCode)
        }

        let completion = try JSONDecoder().decode(AICompletionResponse.self, from: data)

        guard let content = completion.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        if AppConfiguration.shouldLogNetworkRequests {
            print("📥 AI Response: \(content.prefix(200))...")
        }

        return content
    }

    // MARK: - Prompt Builders
    private func buildPlanningPrompt(
        goal: Goal,
        profile: UserProfile,
        commitments: [Event]
    ) -> String {
        let commitmentSummary = commitments.isEmpty
            ? "No existing commitments"
            : "Existing weekly commitments: \(commitments.count) events"

        return """
        Create a detailed, actionable plan to achieve the following goal.

        GOAL DETAILS:
        - Title: \(goal.title)
        - Description: \(goal.description ?? "No additional details")
        - Target Date: \(goal.targetDate?.formatted(as: .mediumDate) ?? "Flexible (recommend a timeline)")
        - Category: \(goal.category.displayName)

        USER PROFILE:
        - Name: \(profile.name)
        - Occupation: \(profile.occupation ?? "Not specified")
        - Available hours per week: \(profile.weeklyAvailableHours)
        - Interests: \(profile.interests.joined(separator: ", "))
        - \(commitmentSummary)

        REQUIREMENTS:
        1. Create 3-5 distinct phases with clear milestones
        2. Each phase should have 5-10 specific, actionable tasks
        3. Tasks should be realistic and achievable within the user's available time
        4. Include estimated duration for each task (in minutes)
        5. Consider the user's background and interests when suggesting tasks
        6. Provide helpful resources (books, websites, courses) where applicable

        Respond with a JSON object in this exact format:
        {
            "phases": [
                {
                    "title": "Phase title",
                    "description": "What this phase accomplishes",
                    "durationWeeks": 4,
                    "tasks": [
                        {
                            "title": "Task title",
                            "description": "Detailed task description",
                            "durationMinutes": 60,
                            "resources": ["resource1", "resource2"]
                        }
                    ]
                }
            ],
            "weeklyCommitmentHours": 10,
            "estimatedCompletionDate": "2024-06-15",
            "summary": "Brief summary of the plan"
        }
        """
    }

    private func buildAdjustmentPrompt(
        schedule: AISchedule,
        goal: Goal,
        completed: [AISchedule.ScheduledTask],
        missed: [AISchedule.ScheduledTask]
    ) -> String {
        return """
        Adjust the following goal schedule based on user progress.

        GOAL: \(goal.title)
        CURRENT PROGRESS: \(Int(schedule.overallProgress * 100))%

        COMPLETED TASKS (\(completed.count)):
        \(completed.map { "- \($0.title)" }.joined(separator: "\n"))

        MISSED TASKS (\(missed.count)):
        \(missed.map { "- \($0.title) (was due: \($0.scheduledDate.shortDateString))" }.joined(separator: "\n"))

        REMAINING PHASES: \(schedule.phases.filter { !$0.isCompleted }.count)
        DAYS REMAINING: \(schedule.daysRemaining)

        Please provide:
        1. Rescheduled dates for missed tasks
        2. Any adjustments to remaining tasks
        3. Updated estimated completion date

        Respond with JSON containing the adjusted schedule.
        """
    }

    private func buildProgressAnalysisPrompt(goal: Goal, schedule: AISchedule) -> String {
        return """
        Analyze progress on the following goal and provide insights.

        GOAL: \(goal.title)
        CATEGORY: \(goal.category.displayName)

        PROGRESS METRICS:
        - Overall Progress: \(Int(schedule.overallProgress * 100))%
        - Tasks Completed: \(schedule.completedTasks) of \(schedule.totalTasks)
        - Overdue Tasks: \(schedule.overdueTasks.count)
        - Days Remaining: \(schedule.daysRemaining)
        - On Track: \(schedule.isOnTrack ? "Yes" : "No")

        CURRENT PHASE: \(schedule.currentPhase?.title ?? "N/A")

        Provide a comprehensive analysis with:
        1. Overall score (0-100)
        2. Whether user is on track
        3. Key strengths (what's going well)
        4. Areas for improvement
        5. Specific recommendations

        Respond with JSON:
        {
            "overallScore": 75,
            "onTrack": true,
            "strengths": ["strength1", "strength2"],
            "areasForImprovement": ["area1", "area2"],
            "recommendations": ["rec1", "rec2"],
            "estimatedNewCompletionDate": "2024-06-20"
        }
        """
    }

    private func buildSuggestionsPrompt(
        goal: Goal,
        schedule: AISchedule,
        profile: UserProfile
    ) -> String {
        return """
        Provide personalized suggestions for improving progress on this goal.

        USER: \(profile.name), \(profile.occupation ?? "")
        INTERESTS: \(profile.interests.joined(separator: ", "))

        GOAL: \(goal.title)
        PROGRESS: \(Int(schedule.overallProgress * 100))%
        OVERDUE TASKS: \(schedule.overdueTasks.count)

        Provide 3-5 actionable suggestions that are:
        1. Specific and actionable
        2. Tailored to the user's profile
        3. Motivating and positive

        Respond with JSON:
        {
            "suggestions": ["suggestion1", "suggestion2", "suggestion3"]
        }
        """
    }

    // MARK: - Response Parsers
    private func parseGoalPlanResponse(
        _ response: String,
        goal: Goal,
        profile: UserProfile
    ) throws -> AISchedule {
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let planResponse = try JSONDecoder().decode(AIGoalPlanResponse.self, from: data)

        // Convert AI response to AISchedule
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let estimatedCompletion = dateFormatter.date(from: planResponse.estimatedCompletionDate)
            ?? Calendar.current.date(byAdding: .month, value: 3, to: Date())!

        var currentDate = Date()
        var phases: [AISchedule.Phase] = []

        for phaseResponse in planResponse.phases {
            let phaseEndDate = Calendar.current.date(
                byAdding: .weekOfYear,
                value: phaseResponse.durationWeeks,
                to: currentDate
            )!

            var tasks: [AISchedule.ScheduledTask] = []
            var taskDate = currentDate

            for taskResponse in phaseResponse.tasks {
                let task = AISchedule.ScheduledTask(
                    title: taskResponse.title,
                    description: taskResponse.description,
                    scheduledDate: taskDate,
                    durationMinutes: taskResponse.durationMinutes,
                    resources: taskResponse.resources
                )
                tasks.append(task)

                // Space tasks throughout the phase
                taskDate = Calendar.current.date(byAdding: .day, value: 2, to: taskDate)!
            }

            let phase = AISchedule.Phase(
                title: phaseResponse.title,
                description: phaseResponse.description,
                startDate: currentDate,
                endDate: phaseEndDate,
                tasks: tasks
            )
            phases.append(phase)

            currentDate = phaseEndDate
        }

        return AISchedule(
            phases: phases,
            weeklyCommitmentHours: planResponse.weeklyCommitmentHours,
            estimatedCompletionDate: estimatedCompletion
        )
    }

    private func parseAdjustmentResponse(
        _ response: String,
        currentSchedule: AISchedule
    ) throws -> AISchedule {
        // For now, return the current schedule with minor adjustments
        // In production, parse the full adjustment response
        var updatedSchedule = currentSchedule

        // Reschedule overdue tasks to upcoming dates
        let today = Date()
        var nextAvailableDate = today

        for phaseIndex in updatedSchedule.phases.indices {
            for taskIndex in updatedSchedule.phases[phaseIndex].tasks.indices {
                let task = updatedSchedule.phases[phaseIndex].tasks[taskIndex]
                if task.isOverdue && !task.isCompleted {
                    updatedSchedule.phases[phaseIndex].tasks[taskIndex].scheduledDate = nextAvailableDate
                    nextAvailableDate = Calendar.current.date(byAdding: .day, value: 1, to: nextAvailableDate)!
                }
            }
        }

        return updatedSchedule
    }

    private func parseProgressAnalysisResponse(_ response: String) throws -> ProgressAnalysis {
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let analysisResponse = try JSONDecoder().decode(AIProgressAnalysisResponse.self, from: data)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return ProgressAnalysis(
            analyzedAt: Date(),
            overallScore: analysisResponse.overallScore,
            onTrack: analysisResponse.onTrack,
            strengths: analysisResponse.strengths,
            areasForImprovement: analysisResponse.areasForImprovement,
            recommendations: analysisResponse.recommendations,
            estimatedNewCompletionDate: analysisResponse.estimatedNewCompletionDate.flatMap {
                dateFormatter.date(from: $0)
            }
        )
    }

    private func parseSuggestionsResponse(_ response: String) -> [String] {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let suggestions = json["suggestions"] as? [String] else {
            return []
        }
        return suggestions
    }
}

// MARK: - System Prompts
private enum SystemPrompts {
    static let goalPlanner = """
    You are an expert life coach and productivity specialist with deep knowledge in career development, health & fitness, education, and personal growth.

    Your role is to create detailed, realistic, and actionable plans that help users achieve their goals. You understand that sustainable progress comes from small, consistent steps.

    When creating plans:
    - Be specific and actionable
    - Consider the user's available time and commitments
    - Provide realistic timelines
    - Include helpful resources when relevant
    - Balance ambition with practicality

    Always respond with valid JSON in the exact format requested.
    """

    static let scheduleAdjuster = """
    You are an adaptive scheduling assistant that helps users stay on track with their goals.

    When adjusting schedules:
    - Prioritize missed tasks appropriately
    - Don't overload upcoming days
    - Consider momentum and motivation
    - Provide encouraging but realistic adjustments

    Always respond with valid JSON.
    """

    static let progressAnalyzer = """
    You are a progress analysis expert who provides constructive feedback on goal progress.

    When analyzing:
    - Be encouraging but honest
    - Highlight specific achievements
    - Provide actionable improvement suggestions
    - Consider context and circumstances

    Always respond with valid JSON in the exact format requested.
    """

    static let suggestionGenerator = """
    You are a motivational coach who provides personalized suggestions for improvement.

    Your suggestions should be:
    - Specific and immediately actionable
    - Tailored to the user's interests and background
    - Positive and motivating
    - Practical and realistic

    Always respond with valid JSON containing a "suggestions" array.
    """
}
