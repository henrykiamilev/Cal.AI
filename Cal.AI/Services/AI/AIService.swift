import Foundation

/// Protocol defining AI service capabilities for goal planning
protocol AIServiceProtocol {
    /// Generate a complete goal plan with phases and tasks
    func generateGoalPlan(
        goal: Goal,
        userProfile: UserProfile,
        existingCommitments: [Event]
    ) async throws -> AISchedule

    /// Adjust an existing schedule based on progress
    func adjustSchedule(
        currentSchedule: AISchedule,
        goal: Goal,
        completedTasks: [AISchedule.ScheduledTask],
        missedTasks: [AISchedule.ScheduledTask]
    ) async throws -> AISchedule

    /// Analyze progress and provide insights
    func analyzeProgress(
        goal: Goal,
        schedule: AISchedule
    ) async throws -> ProgressAnalysis

    /// Get AI suggestions for improving progress
    func getSuggestions(
        goal: Goal,
        schedule: AISchedule,
        userProfile: UserProfile
    ) async throws -> [String]
}

// MARK: - AI Service Errors
enum AIServiceError: LocalizedError {
    case apiKeyMissing
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case rateLimited
    case serverError(Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key is not configured. Please add your OpenAI API key in settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .decodingError(let error):
            return "Failed to process AI response: \(error.localizedDescription)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let code):
            return "Server error (code: \(code)). Please try again later."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - AI Request/Response Models
struct AICompletionRequest: Codable {
    let model: String
    let messages: [AIMessage]
    let temperature: Double
    let maxTokens: Int
    let responseFormat: ResponseFormat?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
    }

    struct ResponseFormat: Codable {
        let type: String
    }
}

struct AIMessage: Codable {
    let role: String
    let content: String
}

struct AICompletionResponse: Codable {
    let id: String
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let message: AIMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Goal Plan Response (from AI)
struct AIGoalPlanResponse: Codable {
    let phases: [PhaseResponse]
    let weeklyCommitmentHours: Double
    let estimatedCompletionDate: String
    let summary: String?

    struct PhaseResponse: Codable {
        let title: String
        let description: String
        let durationWeeks: Int
        let tasks: [TaskResponse]
    }

    struct TaskResponse: Codable {
        let title: String
        let description: String?
        let durationMinutes: Int
        let resources: [String]?
    }
}

// MARK: - Progress Analysis Response
struct AIProgressAnalysisResponse: Codable {
    let overallScore: Double
    let onTrack: Bool
    let strengths: [String]
    let areasForImprovement: [String]
    let recommendations: [String]
    let estimatedNewCompletionDate: String?
}
