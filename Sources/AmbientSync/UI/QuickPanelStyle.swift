import SwiftUI

struct QuickPanelCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func quickPanelCard() -> some View {
        modifier(QuickPanelCardModifier())
    }
}

struct QuickPanelValuePill: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

struct QuickPanelStatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct QuickPanelMetricTile: View {
    let label: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

struct QuickPanelInsetSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(10)
            .background(Color.primary.opacity(0.028), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.primary.opacity(0.035), lineWidth: 1)
            )
    }
}

struct QuickPanelSparkline: View {
    let values: [Double]
    let tint: Color
    var fixedRange: ClosedRange<Double>? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.055))

                if values.count >= 2 {
                    sparklinePath(in: geometry.size)
                        .stroke(
                            tint,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                } else {
                    Rectangle()
                        .fill(tint.opacity(0.20))
                        .frame(height: 1)
                        .padding(.horizontal, 6)
                        .padding(.bottom, geometry.size.height / 2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Canlı eğilim grafiği")
    }

    private func sparklinePath(in size: CGSize) -> Path {
        let bounds = valueBounds
        let span = max(bounds.upperBound - bounds.lowerBound, 0.0001)
        let horizontalStep = size.width / CGFloat(max(values.count - 1, 1))
        let verticalPadding: CGFloat = 6
        let usableHeight = max(size.height - (verticalPadding * 2), 1)

        var path = Path()
        for (index, value) in values.enumerated() {
            let normalized = min(max((value - bounds.lowerBound) / span, 0), 1)
            let point = CGPoint(
                x: CGFloat(index) * horizontalStep,
                y: verticalPadding + (1 - CGFloat(normalized)) * usableHeight
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }

    private var valueBounds: ClosedRange<Double> {
        if let fixedRange {
            return fixedRange
        }

        guard let minimum = values.min(), let maximum = values.max() else {
            return 0...1
        }

        if abs(maximum - minimum) < 0.001 {
            let padding = max(abs(maximum) * 0.08, 1)
            return (minimum - padding)...(maximum + padding)
        }

        let padding = (maximum - minimum) * 0.12
        return (minimum - padding)...(maximum + padding)
    }
}

struct QuickPanelRingGauge: View {
    let value: Double
    let tint: Color
    let valueText: String
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 10)

            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text(valueText)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(valueText)
    }
}
