import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 60
    var showPercentage: Bool = true
    var gradientColors: [Color] = [.primaryBlue, .secondaryPurple]
    var backgroundColor: Color = Color.gray.opacity(0.2)

    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: normalizedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: normalizedProgress)

            // Percentage text
            if showPercentage {
                Text("\(Int(normalizedProgress * 100))%")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(.textDark)
            }
        }
        .frame(width: size, height: size)
    }
}

struct LinearProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var gradientColors: [Color] = [.primaryBlue, .secondaryPurple]
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var showPercentage: Bool = false

    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showPercentage {
                HStack {
                    Spacer()
                    Text("\(Int(normalizedProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.textGray)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)

                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * normalizedProgress, height: height)
                        .animation(.easeInOut(duration: 0.5), value: normalizedProgress)
                }
            }
            .frame(height: height)
        }
    }
}

struct StepProgress: View {
    let currentStep: Int
    let totalSteps: Int
    var activeColor: Color = .primaryBlue
    var inactiveColor: Color = Color.gray.opacity(0.3)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step < currentStep ? activeColor : inactiveColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == currentStep - 1 ? 1.2 : 1)
                    .animation(.spring(response: 0.3), value: currentStep)

                if step < totalSteps - 1 {
                    Rectangle()
                        .fill(step < currentStep - 1 ? activeColor : inactiveColor)
                        .frame(height: 2)
                        .animation(.easeInOut, value: currentStep)
                }
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 20) {
            ProgressRing(progress: 0.75)
            ProgressRing(progress: 0.5, size: 80, gradientColors: [.successGreen, .accentOrange])
            ProgressRing(progress: 0.25, size: 50, showPercentage: false)
        }

        VStack(spacing: 20) {
            LinearProgressBar(progress: 0.6)
            LinearProgressBar(progress: 0.8, showPercentage: true)
            LinearProgressBar(progress: 0.3, gradientColors: [.successGreen, .accentOrange])
        }

        StepProgress(currentStep: 2, totalSteps: 4)
        StepProgress(currentStep: 3, totalSteps: 5)
    }
    .padding()
}
