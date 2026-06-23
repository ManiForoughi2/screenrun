import SwiftUI
import FamilyControls

struct LimitEditor: View {
    @EnvironmentObject var store: RunStore
    @Environment(\.dismiss) private var dismiss

    @State private var label: String
    @State private var minutes: Int
    @State private var runs: Int
    private let base: LimitConfig
    let onSave: (LimitConfig) -> Void

    init(limit: LimitConfig, onSave: @escaping (LimitConfig) -> Void) {
        self.base = limit
        self.onSave = onSave
        _label = State(initialValue: limit.label)
        _minutes = State(initialValue: limit.minutesPerRun)
        _runs = State(initialValue: limit.runsPerDay)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Text("CANCEL")
                        .font(Theme.mono(14))
                        .foregroundStyle(Theme.dim)
                        .padding(.vertical, 8)
                        .padding(.trailing, 16)
                        .contentShape(Rectangle())
                }
                Spacer()
                Button { save() } label: {
                    Text("SAVE")
                        .font(Theme.mono(14, .bold))
                        .foregroundStyle(Theme.fg)
                        .padding(.vertical, 8)
                        .padding(.leading, 16)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            ScrollView {
                VStack(spacing: 30) {
                    // Label(token) renders Apples real icon + name
                    Label(base.token)
                        .labelStyle(.titleAndIcon)
                        .font(Theme.mono(22, .bold))
                        .foregroundStyle(Theme.fg)
                        .padding(.top, 24)

                    // nickname only used on Live Activity, which cant render the system app name
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("NICKNAME (OPTIONAL)")
                        TextField("", text: $label, prompt: Text("leave blank to use app name").foregroundColor(Theme.dim))
                            .font(Theme.mono(20, .bold))
                            .foregroundStyle(Theme.fg)
                            .tint(Theme.fg)
                            .padding(.vertical, 12)
                            .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .bottom)
                    }

                    if store.isLocked { lockedBanner }

                    presetRow

                    // locked caps upper bound at current value, can tighten not loosen
                    stepperRow(title: "MINUTES PER RUN", value: $minutes,
                               range: 1...(store.isLocked ? base.minutesPerRun : 30), unit: "min")
                    if store.runMode == .perApp {
                        stepperRow(title: "RUNS PER DAY", value: $runs,
                                   range: 1...(store.isLocked ? base.runsPerDay : 12), unit: "runs")
                    }

                    summary

                    if store.canRemove(base) {
                        Button(role: .destructive) {
                            store.remove(base)
                            dismiss()
                        } label: {
                            Text("REMOVE APP")
                                .font(Theme.mono(13, .semibold))
                                .foregroundStyle(Theme.dim)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 24)
                                .contentShape(Rectangle())
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .screenBackground()
    }

    private func fieldLabel(_ t: String) -> some View {
        Text(t).font(Theme.mono(11, .bold)).tracking(2).foregroundStyle(Theme.dim)
    }

    private var lockedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill").font(.system(size: 12, weight: .bold))
            Text("locked — you can only make this stricter")
                .font(Theme.mono(11, .bold))
        }
        .foregroundStyle(Theme.bg)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Theme.fg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func presetLoosens(_ p: RunPreset) -> Bool {
        guard store.isLocked else { return false }
        let runRaises = store.runMode == .perApp && p.runs > base.runsPerDay
        return p.minutes > base.minutesPerRun || runRaises
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("PRESETS")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RunPreset.all) { p in
                        let active = minutes == p.minutes && (store.runMode == .shared || runs == p.runs)
                        let blocked = presetLoosens(p)
                        Button {
                            withAnimation(.easeOut(duration: 0.12)) {
                                minutes = p.minutes
                                if store.runMode == .perApp { runs = p.runs }
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(p.name).font(Theme.mono(13, .bold))
                                Text(store.runMode == .shared ? "\(p.minutes)m" : "\(p.minutes)m·\(p.runs)")
                                    .font(Theme.mono(10))
                                    .foregroundStyle(active ? Theme.bg.opacity(0.7) : Theme.dim)
                            }
                            .foregroundStyle(active ? Theme.bg : Theme.fg)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(active ? Theme.fg : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.fg, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(blocked)
                        .opacity(blocked ? 0.3 : 1)
                    }
                }
            }
        }
    }

    private func stepperRow(title: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldLabel(title)
            HStack(spacing: 18) {
                stepButton("–") { if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 } }
                Text("\(value.wrappedValue)")
                    .font(Theme.mono(40, .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.fg)
                    .frame(minWidth: 70)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(Theme.mono(14))
                    .foregroundStyle(Theme.dim)
                Spacer()
                stepButton("+") { if value.wrappedValue < range.upperBound { value.wrappedValue += 1 } }
            }
        }
    }

    private func stepButton(_ glyph: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.12)) { action() }
        } label: {
            Text(glyph)
                .font(Theme.mono(24, .bold))
                .foregroundStyle(Theme.fg)
                .frame(width: 50, height: 50)
                .overlay(Circle().stroke(Theme.fg, lineWidth: 1.2))
                .contentShape(Circle())
        }
    }

    private var summary: some View {
        Text("\(runs) runs · \(minutes) min each · \(runs * minutes) min/day total")
            .font(Theme.mono(12))
            .foregroundStyle(Theme.dim)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
    }

    private func save() {
        var updated = base
        // empty label is fine, rows fall back to Apples real name; nickname only overrides Live Activity
        updated.label = label.trimmingCharacters(in: .whitespaces)
        updated.minutesPerRun = minutes
        updated.runsPerDay = runs
        onSave(updated)
        dismiss()
    }
}
