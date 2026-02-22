import SwiftUI
import CareKit

private enum TimelineMetrics {
    static let barWidth: CGFloat = 10
    static let barLeading: CGFloat = 28
    static let rowHeight: CGFloat = 72

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

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in

                if index > 0 {
                    TimelineGap(
                        from: items[index - 1].date,
                        to: items[index].date
                    )
                    .overlay {
                        GradientSegment(
                            from: items[index - 1].normalizedValue,
                            to: items[index].normalizedValue
                        )
                    }
                }

                Rectangle()
                    .fill(TimelineColor.color(for: items[index].normalizedValue))
                    .frame(height: TimelineMetrics.rowHeight)
            }
        }
        .frame(width: TimelineMetrics.barWidth)
        .padding(.leading, TimelineMetrics.barLeading)
    }
}

struct GradientSegment: View {
    let from: Double
    let to: Double

    var body: some View {
        LinearGradient(
            colors: [
                TimelineColor.color(for: from),
                TimelineColor.color(for: to)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}


struct TimelineRow: View {
    let item: TimelineViewModel.Item

    var body: some View {
        ZStack(alignment: .leading) {

            TimelineMarker(value: item.normalizedValue)

            VStack(alignment: .leading, spacing: 6) {
                Spacer(minLength: 10)

                Text(item.title).font(.headline)

                Text(item.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.outcomeText)
                    .font(.subheadline)

                Spacer(minLength: 10)
            }
            .padding(.leading, TimelineMetrics.contentLeading)
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
                .frame(width: 22, height: 22)
                .blur(radius: 2)
                .opacity(0.55)

            Circle()
                .fill(TimelineColor.color(for: value))
                .frame(width: 14, height: 14)

            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                .frame(width: 14, height: 14)
                .blendMode(.softLight)
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
