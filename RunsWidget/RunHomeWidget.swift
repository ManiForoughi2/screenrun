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

// dots-only: runs left as pips, no number. listed first in the bundle so it's
// the default the gallery offers.
struct RunDotsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RunDotsWidget", provider: RunProvider()) { entry in
            if #available(iOS 17.0, *) {
                RunWidgetView(entry: entry, showNumber: false)
                    .containerBackground(.background, for: .widget)
            } else {
                RunWidgetView(entry: entry, showNumber: false)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("Runs Left · Dots")
        .description("Runs left in your shared pool, shown as dots.")
        .supportedFamilies(Self.families)
    }

    static let families: [WidgetFamily] = {
        if #available(iOS 16.0, *) {
            return [.systemSmall, .systemMedium,
                    .accessoryCircular, .accessoryRectangular, .accessoryInline]
        }
        return [.systemSmall, .systemMedium]
    }()
}

struct RunHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RunHomeWidget", provider: RunProvider()) { entry in
            if #available(iOS 17.0, *) {
                // containerBackground required iOS17+, padding fallback below
                RunWidgetView(entry: entry, showNumber: true)
                    .containerBackground(.background, for: .widget)
            } else {
                RunWidgetView(entry: entry, showNumber: true)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .configurationDisplayName("Runs Left · Number")
        .description("See how many runs are left in your shared pool.")
        .supportedFamilies(RunDotsWidget.families)
    }
}

private struct RunWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RunEntry
    let showNumber: Bool

    private var isLockScreen: Bool {
        if #available(iOS 16.0, *) {
            return family == .accessoryCircular
                || family == .accessoryRectangular
                || family == .accessoryInline
        }
        return false
    }

    var body: some View {
        if isLockScreen {
            LockScreenView(entry: entry, showNumber: showNumber, family: family)
        } else if let label = entry.snapshot.activeLabel, let endsAt = entry.snapshot.activeEndsAt {
            ActiveRunWidget(label: label, endsAt: endsAt)
        } else if !entry.snapshot.isPooled {
            // per-app mode has no single pool number to show, so the widget cant render it
            UnpooledWidget()
        } else {
            PoolWidget(left: entry.snapshot.poolLeft, total: entry.snapshot.poolTotal,
                       showNumber: showNumber)
        }
    }
}

// lock-screen accessory rendering. monochrome/vibrant, very small, so keep it to
// a count or a compact pip row. per-app mode has no pool number, show a dash.
@available(iOS 16.0, *)
private struct LockScreenView: View {
    let entry: RunEntry
    let showNumber: Bool
    let family: WidgetFamily

    private var left: Int { entry.snapshot.poolLeft }
    private var total: Int { entry.snapshot.poolTotal }
    private var pooled: Bool { entry.snapshot.isPooled }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                // single line, system tints it. text is unavoidable here
                Text(pooled ? "\(left)/\(total) runs" : "shared pool only")
            case .accessoryCircular:
                if pooled {
                    if showNumber {
                        Text("\(left)").font(.system(size: 26, weight: .semibold)).minimumScaleFactor(0.4)
                    } else {
                        // dots wrap into the circle
                        DotGrid(left: left, total: total, dotSize: 7)
                    }
                } else {
                    Text("—").font(.system(size: 22, weight: .semibold))
                }
            default: // accessoryRectangular
                if pooled {
                    HStack(spacing: 6) {
                        if showNumber {
                            Text("\(left)").font(.system(size: 22, weight: .semibold)).monospacedDigit()
                        }
                        DotGrid(left: left, total: total, dotSize: 8)
                    }
                } else {
                    Text("shared pool only").font(.system(size: 13, weight: .medium))
                }
            }
        }
        .widgetURL(URL(string: "\(deepLinkScheme)://home"))
    }
}

// pips that wrap, for tight accessory spaces. plain primary color so the system
// vibrant rendering can tint them on the lock screen.
@available(iOS 16.0, *)
private struct DotGrid: View {
    let left: Int
    let total: Int
    let dotSize: CGFloat

    private var columns: [GridItem] {
        let perRow = total <= 4 ? total : Int(ceil(Double(total) / 2.0))
        return Array(repeating: GridItem(.fixed(dotSize), spacing: dotSize * 0.5),
                     count: max(perRow, 1))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: dotSize * 0.5) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Circle()
                    .fill(i < left ? Color.primary : Color.clear)
                    .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

// shared-pool: runs left in the pool. minimal, no text labels. dots always show;
// the number is opt-in so we can offer a dots-only variant.
private struct PoolWidget: View {
    let left: Int
    let total: Int
    let showNumber: Bool

    var body: some View {
        VStack(spacing: showNumber ? 12 : 0) {
            if showNumber {
                Text("\(left)")
                    .font(W.mono(72))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(W.fg)
            }
            Pips(left: left, total: total, dotSize: showNumber ? 9 : 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "\(deepLinkScheme)://home"))
    }
}

// per-app mode: tell the user widgets need the shared pool turned on.
private struct UnpooledWidget: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("RUNS")
                .font(W.mono(14))
                .tracking(2)
                .foregroundStyle(W.fg)
            Text("widgets only work\nwith shared pool")
                .font(W.mono(12))
                .multilineTextAlignment(.center)
                .foregroundStyle(W.dim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "\(deepLinkScheme)://home"))
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
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(W.fg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "\(deepLinkScheme)://home"))
    }
}

private struct Pips: View {
    let left: Int
    let total: Int
    var dotSize: CGFloat = 9
    var body: some View {
        HStack(spacing: dotSize * 0.55) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Circle()
                    .fill(i < left ? W.fg : Color.clear)
                    .overlay(Circle().stroke(W.fg, lineWidth: 1))
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
}

