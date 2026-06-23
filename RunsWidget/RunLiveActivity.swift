import ActivityKit
import WidgetKit
import SwiftUI

struct RunLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            LockScreenRunView(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RUNNING")
                            .font(.system(.caption2, design: .monospaced).weight(.bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(context.attributes.appLabel)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startedAt...context.state.endsAt, countsDown: true)
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.runsLeftAfter) runs left after this")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
            } compactLeading: {
                Text(String(context.attributes.appLabel.prefix(1)))
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.trailing, 2)
            } compactTrailing: {
                Text(timerInterval: context.state.startedAt...context.state.endsAt, countsDown: true)
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .fixedSize()
                    .foregroundStyle(.white)
                    .padding(.leading, 2)
            } minimal: {
                Text(timerInterval: context.state.startedAt...context.state.endsAt, countsDown: true)
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .fixedSize()
                    .foregroundStyle(.white)
            }
            .keylineTint(.white)
        }
    }
}

private struct LockScreenRunView: View {
    let context: ActivityViewContext<RunActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RUNNING")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(context.attributes.appLabel)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 8)
                Text(timerInterval: context.state.startedAt...context.state.endsAt, countsDown: true)
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.white)
            }

            ProgressView(timerInterval: context.state.startedAt...context.state.endsAt, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(.white)
            .labelsHidden()
        }
        .padding(20)
    }
}
