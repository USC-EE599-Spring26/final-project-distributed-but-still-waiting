import SwiftUI
import CareKit

private enum TimelineMetrics {
    static let barWidth: CGFloat = 15
    static let barLeading: CGFloat = 28
    static let rowHeight: CGFloat = 100

    static let pointsPerDay: CGFloat = 6   // time scale

    static var contentLeading: CGFloat {
        barLeading + barWidth + 16
    }

    static var markerCenterX: CGFloat {
        barLeading + barWidth / 2
    }

    static func gapHeight(from newer: Date, to older: Date) -> CGFloat {
        let days = Calendar.current.dateComponents([.day], from: older, to: newer).day ?? 0
        return CGFloat(max(abs(days), 1)) * pointsPerDay
    }
}


struct TimelineView: View {
    @Environment(\.careStore) private var careStore
    @StateObject private var viewModel = TimelineViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Timeline...")
                } else if viewModel.items.isEmpty {
                    ContentUnavailableView("No Activity Yet", systemImage: "figure.walk")
                } else {
                    TimelineScrollView(items: viewModel.items)
                }
            }
            .navigationTitle("Timeline")
        }
        .task {
            viewModel.configure(with: careStore)
            await viewModel.loadTimeline()
        }
    }
}


struct TimelineScrollView: View {
    let items: [TimelineViewModel.Item]

    var body: some View {
        ScrollView {
            ZStack(alignment: .leading) {
                HeatmapBar(items: items)

                VStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        if index > 0 {
                            TimelineGap(
                                from: items[index - 1].date,
                                to: items[index].date
                            )
                        }

                        TimelineRow(item: items[index])
                    }
                }
            }
            .padding(.top, 20)
        }
    }
}


struct TimelineGap: View {
    let from: Date
    let to: Date

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: TimelineMetrics.gapHeight(from: from, to: to))
            .overlay {
                TimelineTickOverlay(from: from, to: to)
            }
    }
}


struct HeatmapBar: View {
    let items: [TimelineViewModel.Item]

    private struct Stop: Identifiable {
        let id = UUID()
        let location: CGFloat   // 0 → 1 along entire bar
        let color: Color
    }

    private func gradientStops(totalHeight: CGFloat) -> [Gradient.Stop] {
        guard items.count > 0 else { return [] }

        var yCursor: CGFloat = 0
        var stops: [Gradient.Stop] = []

        for i in 0..<items.count {

            let item = items[i]

            // Add stop at the TOP of this row
            let location = yCursor / totalHeight
            stops.append(.init(
                color: TimelineColor.color(for: item.normalizedValue),
                location: location
            ))

            // Advance by row height
            yCursor += TimelineMetrics.rowHeight

            // Add gap if needed
            if i < items.count - 1 {
                let gap = TimelineMetrics.gapHeight(
                    from: item.date,
                    to: items[i + 1].date
                )
                yCursor += gap
            }
        }

        // Ensure final stop reaches bottom
        stops.append(.init(
            color: TimelineColor.color(for: items.last!.normalizedValue),
            location: 1.0
        ))

        return stops
    }

    private func totalHeight() -> CGFloat {
        guard items.count > 0 else { return 0 }

        var height: CGFloat = 0

        for i in 0..<items.count {
            height += TimelineMetrics.rowHeight

            if i < items.count - 1 {
                height += TimelineMetrics.gapHeight(
                    from: items[i].date,
                    to: items[i + 1].date
                )
            }
        }

        return height
    }

    var body: some View {

        let height = totalHeight()
        let stops = gradientStops(totalHeight: height)

        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: stops),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // 🔹 subtle inner light — makes it feel rounded
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                    .blendMode(.softLight)
            }

            // 🔹 micro edge shading — removes “cut” look
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.08),
                                Color.clear,
                                Color.black.opacity(0.06)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blendMode(.overlay)
            }

            // 🔹 soft shadow for separation from background
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)

            .frame(width: TimelineMetrics.barWidth)
            .frame(height: height)
            .padding(.leading, TimelineMetrics.barLeading)

            // important for smooth gradient rasterization
            .compositingGroup()
            .drawingGroup(opaque: false)
    }
}


struct TimelineRow: View {
    let item: TimelineViewModel.Item

    var body: some View {
        ZStack(alignment: .leading) {

            TimelineMarker(value: item.normalizedValue)

            VStack(alignment: .leading, spacing: 4) {

                // Title
                Text(item.title)
                    .font(.body.weight(.semibold))

                // Date
                Text(item.date, format: .dateTime.month().day().year())
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                // Value
                Text(item.outcomeText)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.primary)

                // Clinical interpretation
                Text(TimelineInsight.message(for: item.normalizedValue))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            .padding(.leading, TimelineMetrics.contentLeading)
            .padding(.vertical, 10)
        }
        .frame(height: TimelineMetrics.rowHeight)
    }
}


struct TimelineMarker: View {
    let value: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(TimelineColor.color(for: value))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
        }
        .position(x: TimelineMetrics.markerCenterX, y: TimelineMetrics.rowHeight / 2)
    }
}

struct TimelineTickOverlay: View {
    let from: Date
    let to: Date

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let calendar = Calendar.current
                let totalDays = calendar.dateComponents([.day], from: to, to: from).day ?? 0
                guard totalDays > 0 else { return }

                let pxPerDay = size.height / CGFloat(totalDays)

                for offset in 0...totalDays {
                    guard let date = calendar.date(byAdding: .day, value: offset, to: to) else { continue }
                    let y = CGFloat(offset) * pxPerDay

                    if calendar.component(.weekday, from: date) == 1 {
                        var path = Path()
                        path.move(to: CGPoint(x: TimelineMetrics.barLeading, y: y))
                        path.addLine(to: CGPoint(x: TimelineMetrics.barLeading + TimelineMetrics.barWidth, y: y))
                        context.stroke(path, with: .color(.secondary.opacity(0.18)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
