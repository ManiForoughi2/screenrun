import WidgetKit
import SwiftUI

// widget runs in its own process, cant reach the app target Theme, mirror it here
private enum W {
    static let fontName = "FairfaxHD"
    static let scale: CGFloat = 1.18
    static func mono(_ size: CGFloat) -> Font { .custom(fontName, size: size * scale) }

    static let fg = Color.primary
    static let dim = Color.primary.opacity(0.45)
    static let hairline = Color.primary.opacity(0.14)
}

// must match the screenrun:// scheme the app registers and handles
private let deepLinkScheme = "screenrun"

private struct RunEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

private struct RunProvider: TimelineProvider {
    private func read() -> WidgetSnapshot {
        guard let data = AppGroup.defaults.data(forKey: StoreKey.widgetSnapshot),
              let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snap
    }

    func placeholder(in context: Context) -> RunEntry {
        RunEntry(date: Date(), snapshot: WidgetSnapshot(
            items: [.init(id: UUID(), label: "X", minutesPerRun: 3, runsLeft: 2, runsTotal: 4)],
            activeLabel: nil, activeEndsAt: nil))
    }

    func getSnapshot(in context: Context, completion: @escaping (RunEntry) -> Void) {
        completion(RunEntry(date: Date(), snapshot: read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RunEntry>) -> Void) {
        let entry = RunEntry(date: Date(), snapshot: read())
        // refresh when the active run ends, else hold 30min
        let next = entry.snapshot.activeEndsAt ?? Date().addingTimeInterval(60 * 30)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct RunHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RunHomeWidget", provider: RunProvider()) { entry in
            if #available(iOS 17.0, *) {
                // containerBackground required iOS17+, padding fallback below
                RunWidgetView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                RunWidgetView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("Start a Run")
        .description("Tap an app to start a run without opening Runs first.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct RunWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: RunEntry

    var body: some View {
        if let label = entry.snapshot.activeLabel, let endsAt = entry.snapshot.activeEndsAt {
            ActiveRunWidget(label: label, endsAt: endsAt)
        } else if entry.snapshot.items.isEmpty {
            EmptyWidget()
        } else if family == .systemSmall {
            SmallWidget(item: entry.snapshot.items[0])
        } else {
            MediumWidget(items: entry.snapshot.items)
        }
    }
}

private struct ActiveRunWidget: View {
    let label: String
    let endsAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RUNNING")
                .font(W.mono(11))
                .tracking(2)
                .foregroundStyle(W.dim)
            Text(label.uppercased())
                .font(W.mono(20))
                .foregroundStyle(W.fg)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(timerInterval: Date()...endsAt, countsDown: true)
                .font(W.mono(34))
                .monospacedDigit()
                .foregroundStyle(W.fg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "\(deepLinkScheme)://home"))
    }
}

private struct EmptyWidget: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("RUNS")
                .font(W.mono(14))
                .tracking(2)
                .foregroundStyle(W.fg)
            Text("choose apps to begin")
                .font(W.mono(11))
                .foregroundStyle(W.dim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "\(deepLinkScheme)://home"))
    }
}

private struct SmallWidget: View {
    let item: WidgetSnapshot.Item

    private var canRun: Bool { item.runsLeft > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.label.uppercased())
                    .font(W.mono(18))
                    .foregroundStyle(W.fg)
                    .lineLimit(1)
                Spacer()
            }
            Pips(left: item.runsLeft, total: item.runsTotal)
            Spacer(minLength: 2)
            Text(canRun ? "START RUN" : "DONE TODAY")
                .font(W.mono(13))
                .foregroundStyle(canRun ? Color(.systemBackground) : W.dim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(canRun ? W.fg : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(W.fg, lineWidth: 1.1))
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .opacity(canRun ? 1 : 0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(runURL(for: item))
    }
}

private struct MediumWidget: View {
    let items: [WidgetSnapshot.Item]

    var body: some View {
        VStack(spacing: 0) {
            Text("START A RUN")
                .font(W.mono(11))
                .tracking(3)
                .foregroundStyle(W.dim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            ForEach(Array(items.prefix(3).enumerated()), id: \.element.id) { idx, item in
                Link(destination: runURL(for: item)!) {
                    Row(item: item)
                }
                if idx < min(items.count, 3) - 1 {
                    Rectangle().fill(W.hairline).frame(height: 1).padding(.vertical, 7)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private struct Row: View {
        let item: WidgetSnapshot.Item
        private var canRun: Bool { item.runsLeft > 0 }
        var body: some View {
            HStack(spacing: 10) {
                Text(item.label.uppercased())
                    .font(W.mono(16))
                    .foregroundStyle(canRun ? W.fg : W.dim)
                    .lineLimit(1)
                Spacer()
                Pips(left: item.runsLeft, total: item.runsTotal)
                Text(canRun ? "▶" : "·")
                    .font(W.mono(15))
                    .foregroundStyle(canRun ? W.fg : W.dim)
            }
        }
    }
}

private struct Pips: View {
    let left: Int
    let total: Int
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Circle()
                    .fill(i < left ? W.fg : Color.clear)
                    .overlay(Circle().stroke(W.fg, lineWidth: 1))
                    .frame(width: 9, height: 9)
            }
        }
    }
}

private func runURL(for item: WidgetSnapshot.Item) -> URL? {
    item.runsLeft > 0
        ? URL(string: "\(deepLinkScheme)://run/\(item.id.uuidString)")
        : URL(string: "\(deepLinkScheme)://home")
}
