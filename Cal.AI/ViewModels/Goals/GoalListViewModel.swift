import SwiftUI
import Combine

@MainActor
final class GoalListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var activeGoals: [Goal] = []
    @Published var completedGoals: [Goal] = []
    @Published var isLoading = false
    @Published var showingGoalForm = false
    @Published var selectedGoal: Goal?
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let goalRepository: GoalRepository
    private let planningEngine: GoalPlanningEngine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var totalActiveGoals: Int {
        activeGoals.count
    }

    var goalsWithAIPlan: Int {
        activeGoals.filter { $0.hasAIPlan }.count
    }

    var averageProgress: Double {
        guard !activeGoals.isEmpty else { return 0 }
        let total = activeGoals.reduce(0.0) { $0 + $1.progress }
        return total / Double(activeGoals.count)
    }

    // MARK: - Initialization
    init(
        goalRepository: GoalRepository = GoalRepository(),
        planningEngine: GoalPlanningEngine = .shared
    ) {
        self.goalRepository = goalRepository
        self.planningEngine = planningEngine

        setupBindings()
        loadGoals()
    }

    private func setupBindings() {
        goalRepository.$activeGoals
            .receive(on: DispatchQueue.main)
            .assign(to: &$activeGoals)
    }

    // MARK: - Data Loading
    func loadGoals() {
        isLoading = true
        activeGoals = goalRepository.fetchActive()
        completedGoals = goalRepository.fetchCompleted()
        isLoading = false
    }

    func refresh() {
        goalRepository.refresh()
        loadGoals()
    }

    // MARK: - Goal Management
    func createGoal(_ goal: Goal) {
        goalRepository.create(goal)
        loadGoals()
    }

    func updateGoal(_ goal: Goal) {
        goalRepository.update(goal)
        loadGoals()
    }

    func deleteGoal(_ goal: Goal) {
        goalRepository.delete(goal)
        loadGoals()
    }

    // MARK: - Goal Form
    func showNewGoalForm() {
        selectedGoal = nil
        showingGoalForm = true
    }

    func showGoalDetail(_ goal: Goal) {
        selectedGoal = goal
    }

    func dismissGoalForm() {
        showingGoalForm = false
        selectedGoal = nil
    }
}

@MainActor
final class GoalDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var goal: Goal
    @Published var isGeneratingPlan = false
    @Published var isAnalyzing = false
    @Published var progressAnalysis: ProgressAnalysis?
    @Published var suggestions: [String] = []
    @Published var showingAISchedule = false
    @Published var showingEditForm = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let goalRepository: GoalRepository
    private let planningEngine: GoalPlanningEngine

    // MARK: - Computed Properties
    var hasAIPlan: Bool {
        goal.aiSchedule != nil
    }

    var canGeneratePlan: Bool {
        !isGeneratingPlan && AppConfiguration.isAIEnabled
    }

    var shouldShowAdjustButton: Bool {
        hasAIPlan && planningEngine.shouldAdjustSchedule(for: goal)
    }

    // MARK: - Initialization
    init(
        goal: Goal,
        goalRepository: GoalRepository = GoalRepository(),
        planningEngine: GoalPlanningEngine = .shared
    ) {
        self.goal = goal
        self.goalRepository = goalRepository
        self.planningEngine = planningEngine
    }

    // MARK: - AI Plan Generation
    func generateAIPlan() async {
        isGeneratingPlan = true
        errorMessage = nil

        do {
            let schedule = try await planningEngine.generatePlan(for: goal)
            goal.aiSchedule = schedule
            goal.lastAIUpdateAt = Date()
            goalRepository.update(goal)
            refreshGoal()
        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingPlan = false
    }

    func adjustSchedule() async {
        guard hasAIPlan else { return }

        isGeneratingPlan = true
        errorMessage = nil

        do {
            let adjustedSchedule = try await planningEngine.adjustSchedule(for: goal)
            goal.aiSchedule = adjustedSchedule
            goalRepository.update(goal)
            refreshGoal()
        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingPlan = false
    }

    // MARK: - Progress Analysis
    func analyzeProgress() async {
        guard hasAIPlan else { return }

        isAnalyzing = true

        do {
            progressAnalysis = try await planningEngine.analyzeProgress(for: goal)
            suggestions = try await planningEngine.getSuggestions(for: goal)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    // MARK: - Task Completion
    func markTaskComplete(_ taskId: UUID) {
        guard planningEngine.markTaskComplete(taskId: taskId, in: goal) else { return }
        refreshGoal()
    }

    func markTaskIncomplete(_ taskId: UUID) {
        guard planningEngine.markTaskIncomplete(taskId: taskId, in: goal) else { return }
        refreshGoal()
    }

    // MARK: - Milestone Management
    func toggleMilestoneComplete(_ milestoneId: UUID) {
        goalRepository.toggleMilestoneComplete(milestoneId, in: goal.id)
        refreshGoal()
    }

    func addMilestone(_ milestone: Milestone) {
        goalRepository.addMilestone(milestone, to: goal.id)
        refreshGoal()
    }

    // MARK: - Refresh
    func refreshGoal() {
        if let updated = goalRepository.fetch(byId: goal.id) {
            goal = updated
        }
    }

    // MARK: - Delete
    func deleteGoal() {
        goalRepository.delete(goal)
    }
}
