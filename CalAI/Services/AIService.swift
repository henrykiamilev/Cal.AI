import Foundation

actor AIService {
    static let shared = AIService()

    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var apiKey: String? {
        KeychainManager.shared.retrieve(key: "openai_api_key")
    }

    private init() {}

    struct AIResponse: Codable {
        let choices: [Choice]
    }

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }

    struct ScheduleRequest: Encodable {
        let model: String = "gpt-4"
        let messages: [ChatMessage]
        let temperature: Double = 0.7
        let max_tokens: Int = 2000
    }

    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    func generateGoalSchedule(
        goal: Goal,
        userProfile: UserProfile,
        existingEvents: [CalendarEvent]
    ) async throws -> AISchedule {
        guard let apiKey = apiKey else {
            throw AIError.apiKeyMissing
        }

        let prompt = buildSchedulePrompt(goal: goal, userProfile: userProfile, existingEvents: existingEvents)

        let request = ScheduleRequest(messages: [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: prompt)
        ])

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError(statusCode: httpResponse.statusCode)
        }

        let aiResponse = try JSONDecoder().decode(AIResponse.self, from: data)

        guard let content = aiResponse.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        return try parseScheduleResponse(content)
    }

    func adjustSchedule(
        currentSchedule: AISchedule,
        completedActivities: [ScheduledActivity],
        missedActivities: [ScheduledActivity],
        userFeedback: String?
    ) async throws -> AISchedule {
        guard let apiKey = apiKey else {
            throw AIError.apiKeyMissing
        }

        let prompt = buildAdjustmentPrompt(
            currentSchedule: currentSchedule,
            completedActivities: completedActivities,
            missedActivities: missedActivities,
            userFeedback: userFeedback
        )

        let request = ScheduleRequest(messages: [
            ChatMessage(role: "system", content: adjustmentSystemPrompt),
            ChatMessage(role: "user", content: prompt)
        ])

        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError(statusCode: httpResponse.statusCode)
        }

        let aiResponse = try JSONDecoder().decode(AIResponse.self, from: data)

        guard let content = aiResponse.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        return try parseScheduleResponse(content)
    }

    private var systemPrompt: String {
        """
        You are an expert life coach and schedule optimizer. Your job is to create personalized,
        actionable schedules that help users achieve their goals. Consider the user's existing
        commitments, work schedule, sleep patterns, and available time.

        Always respond with a valid JSON object in this exact format:
        {
            "weeklySchedule": [
                {
                    "dayOfWeek": 1,
                    "activities": [
                        {
                            "title": "Activity name",
                            "description": "Brief description",
                            "startTime": "HH:mm",
                            "duration": 60
                        }
                    ]
                }
            ],
            "recommendations": ["Tip 1", "Tip 2", "Tip 3"],
            "estimatedTimeToGoal": "6-12 months",
            "difficultyLevel": "moderate"
        }

        dayOfWeek: 1 = Sunday, 2 = Monday, ... 7 = Saturday
        duration: in minutes
        difficultyLevel: "easy", "moderate", "challenging", or "intense"
        """
    }

    private var adjustmentSystemPrompt: String {
        """
        You are an expert life coach reviewing a user's progress on their goal schedule.
        Based on their completed and missed activities, adjust the schedule to be more realistic
        while still pushing them toward their goal.

        If they're consistently missing activities, reduce intensity or reschedule to better times.
        If they're completing everything easily, consider adding more challenge.

        Respond with the same JSON format as the original schedule.
        """
    }

    private func buildSchedulePrompt(goal: Goal, userProfile: UserProfile, existingEvents: [CalendarEvent]) -> String {
        var prompt = """
        Create a personalized weekly schedule to help achieve this goal:

        GOAL: \(goal.title)
        DESCRIPTION: \(goal.description)
        CATEGORY: \(goal.category.rawValue)
        TARGET DATE: \(goal.targetDate?.formatted(date: .long, time: .omitted) ?? "Flexible")

        USER PROFILE:
        """

        if let age = userProfile.profileInfo.age {
            prompt += "\n- Age: \(age)"
        }

        if let occupation = userProfile.profileInfo.occupation {
            prompt += "\n- Occupation: \(occupation)"
        }

        if let workSchedule = userProfile.profileInfo.workSchedule {
            let workDays = workSchedule.workDays.map { day -> String in
                let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                return days[day]
            }.joined(separator: ", ")
            prompt += "\n- Work Days: \(workDays) (\(workSchedule.startTime) - \(workSchedule.endTime))"
        }

        if let sleepSchedule = userProfile.profileInfo.sleepSchedule {
            prompt += "\n- Sleep Schedule: \(sleepSchedule.bedtime) - \(sleepSchedule.wakeTime)"
        }

        if let fitnessLevel = userProfile.profileInfo.fitnessLevel {
            prompt += "\n- Fitness Level: \(fitnessLevel.rawValue)"
        }

        if let availableHours = userProfile.profileInfo.availableHoursPerWeek {
            prompt += "\n- Available Hours Per Week: \(availableHours)"
        }

        if !existingEvents.isEmpty {
            prompt += "\n\nEXISTING WEEKLY COMMITMENTS:"
            let sortedEvents = existingEvents.sorted { $0.startDate < $1.startDate }
            for event in sortedEvents.prefix(10) {
                let day = Calendar.current.component(.weekday, from: event.startDate)
                let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                prompt += "\n- \(days[day]): \(event.title) (\(event.formattedTimeRange))"
            }
        }

        prompt += """

        Create a realistic, sustainable schedule that:
        1. Respects the user's work hours and sleep schedule
        2. Doesn't conflict with existing commitments
        3. Includes rest days where appropriate
        4. Gradually increases intensity over time
        5. Provides variety to prevent burnout

        Focus on actionable, specific activities with clear durations.
        """

        return prompt
    }

    private func buildAdjustmentPrompt(
        currentSchedule: AISchedule,
        completedActivities: [ScheduledActivity],
        missedActivities: [ScheduledActivity],
        userFeedback: String?
    ) -> String {
        var prompt = """
        Review and adjust this schedule based on user performance:

        CURRENT SCHEDULE:
        \(formatScheduleForPrompt(currentSchedule))

        COMPLETED ACTIVITIES: \(completedActivities.count)
        MISSED ACTIVITIES: \(missedActivities.count)

        COMPLETION RATE: \(calculateCompletionRate(completed: completedActivities.count, missed: missedActivities.count))%
        """

        if !missedActivities.isEmpty {
            prompt += "\n\nMISSED ACTIVITIES:"
            for activity in missedActivities {
                prompt += "\n- \(activity.title) at \(activity.startTime) (\(activity.duration) min)"
            }
        }

        if let feedback = userFeedback, !feedback.isEmpty {
            prompt += "\n\nUSER FEEDBACK: \(feedback)"
        }

        prompt += """

        Adjust the schedule to be more achievable while maintaining progress toward the goal.
        Consider:
        1. Rescheduling frequently missed activities to better times
        2. Adjusting duration based on actual performance
        3. Adding or removing activities based on capacity
        """

        return prompt
    }

    private func formatScheduleForPrompt(_ schedule: AISchedule) -> String {
        var result = ""
        for day in schedule.weeklySchedule.sorted(by: { $0.dayOfWeek < $1.dayOfWeek }) {
            result += "\n\(day.dayName):"
            for activity in day.activities {
                result += "\n  - \(activity.title) at \(activity.startTime) (\(activity.duration) min)"
            }
        }
        return result
    }

    private func calculateCompletionRate(completed: Int, missed: Int) -> Int {
        let total = completed + missed
        guard total > 0 else { return 0 }
        return Int((Double(completed) / Double(total)) * 100)
    }

    private func parseScheduleResponse(_ content: String) throws -> AISchedule {
        // Extract JSON from the response (it might have markdown formatting)
        var jsonString = content

        if let startIndex = content.range(of: "{")?.lowerBound,
           let endIndex = content.range(of: "}", options: .backwards)?.upperBound {
            jsonString = String(content[startIndex..<endIndex])
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIError.parsingError
        }

        let parsed = try JSONDecoder().decode(ParsedSchedule.self, from: jsonData)

        var weeklySchedule: [ScheduleDay] = []
        for day in parsed.weeklySchedule {
            let activities = day.activities.map { activity in
                ScheduledActivity(
                    title: activity.title,
                    description: activity.description ?? "",
                    startTime: activity.startTime,
                    duration: activity.duration
                )
            }
            weeklySchedule.append(ScheduleDay(dayOfWeek: day.dayOfWeek, activities: activities))
        }

        let difficultyLevel: DifficultyLevel
        switch parsed.difficultyLevel.lowercased() {
        case "easy": difficultyLevel = .easy
        case "moderate": difficultyLevel = .moderate
        case "challenging": difficultyLevel = .challenging
        case "intense": difficultyLevel = .intense
        default: difficultyLevel = .moderate
        }

        return AISchedule(
            weeklySchedule: weeklySchedule,
            recommendations: parsed.recommendations,
            estimatedTimeToGoal: parsed.estimatedTimeToGoal,
            difficultyLevel: difficultyLevel
        )
    }

    func setAPIKey(_ key: String) {
        KeychainManager.shared.save(key: "openai_api_key", value: key)
    }
}

private struct ParsedSchedule: Codable {
    let weeklySchedule: [ParsedDay]
    let recommendations: [String]
    let estimatedTimeToGoal: String
    let difficultyLevel: String
}

private struct ParsedDay: Codable {
    let dayOfWeek: Int
    let activities: [ParsedActivity]
}

private struct ParsedActivity: Codable {
    let title: String
    let description: String?
    let startTime: String
    let duration: Int
}

enum AIError: Error, LocalizedError {
    case apiKeyMissing
    case invalidResponse
    case apiError(statusCode: Int)
    case emptyResponse
    case parsingError
    case subscriptionRequired

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key not configured. Please contact support."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .apiError(let code):
            return "AI service error (code: \(code)). Please try again."
        case .emptyResponse:
            return "AI service returned an empty response."
        case .parsingError:
            return "Failed to parse AI response."
        case .subscriptionRequired:
            return "Premium subscription required for AI features."
        }
    }
}
