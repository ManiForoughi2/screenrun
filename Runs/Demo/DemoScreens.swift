import SwiftUI

// demo home screen, mirrors HomeView's real layout with mock app rows.
// on a wide canvas (iPad) the column is capped + vertically centered so the
// screenshot fills the frame instead of stretching thin across the top.
struct DemoHomeView: View {
    let apps = DemoApp.sample

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 700
            let contentW = wide ? min(geo.size.width - 100, 1500) : min(geo.size.width - 40, 620)

            VStack(spacing: 0) {
                HStack {
                    Text("RUNS")
                        .font(Theme.mono(wide ? 24 : 18, .bold))
                        .tracking(3)
                        .foregroundStyle(Theme.fg)
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: wide ? 24 : 18, weight: .medium))
                        .foregroundStyle(Theme.fg)
                        .frame(width: 44, height: 44)
                }
                .frame(width: contentW)
                .padding(.top, wide ? 40 : 12)
                .padding(.bottom, wide ? 28 : 20)

                if wide {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 20),
                                        GridItem(.flexible(), spacing: 20)], spacing: 20) {
                        ForEach(apps) { DemoRunRow(app: $0) }
                    }
                    .frame(width: contentW)
                } else {
                    VStack(spacing: 12) {
                        ForEach(apps) { DemoRunRow(app: $0) }
                    }
                    .frame(width: contentW)
                }

                DemoPoolBar()
                    .frame(width: contentW)
                    .padding(.top, wide ? 22 : 16)

                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .screenBackground()
    }
}

// matches the real RunRow in shared mode: no per-row pips, the pool bar shows the count
private struct DemoRunRow: View {
    let app: DemoApp

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                AppTile(app: app, size: 30)
                Text(app.name)
                    .font(Theme.mono(22, .bold))
                    .foregroundStyle(Theme.fg)
                Spacer()
                Text("\(app.minutesPerRun) MIN / RUN")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.dim)
            }

            Text("START RUN")
                .font(Theme.mono(15, .semibold))
                .foregroundStyle(Theme.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.fg)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.fg, lineWidth: 1.2))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))
    }
}

private struct DemoPoolBar: View {
    let left = 3
    let total = 4

    var body: some View {
        HStack(spacing: 14) {
            Text("RUNS")
                .font(Theme.mono(15, .semibold)).tracking(2)
                .foregroundStyle(Theme.dim)
            HStack(spacing: 9) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < left ? Theme.fg : Color.clear)
                        .overlay(Circle().stroke(Theme.fg, lineWidth: 1.5))
                        .frame(width: 18, height: 18)
                }
            }
            Spacer()
            Text("\(left)/\(total) LEFT")
                .font(Theme.mono(15))
                .foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.bg)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.hairline, lineWidth: 1.2))
        )
    }
}

// stand-in app icon: rounded tile + glyph, since real tokens aren't available
// demo of the block screen iOS shows for a shielded app (mirrors the real shield)
struct DemoBlockedView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // the 3-pill Runs mark
            VStack(alignment: .center, spacing: 9) {
                pill(width: 92)
                pill(width: 74)
                pill(width: 54)
            }
            .padding(.bottom, 30)

            Text("RUNS")
                .font(Theme.mono(34, .bold))
                .tracking(4)
                .foregroundStyle(Theme.fg)

            Text("this app is resting.\nopen Runs to start a run.")
                .font(Theme.mono(15))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.top, 18)

            Spacer()

            Text("DISMISS")
                .font(Theme.mono(15, .semibold))
                .foregroundStyle(Theme.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.fg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }

    private func pill(width: CGFloat) -> some View {
        Capsule().fill(Theme.fg).frame(width: width, height: 16)
    }
}

private struct AppTile: View {
    let app: DemoApp
    var size: CGFloat = 30
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26)
            .fill(Theme.fg)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: app.symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(Theme.bg)
            )
    }
}

// demo active run, mirrors ActiveRunView
struct DemoActiveRunView: View {
    let app = DemoApp.sample[0]
    let remaining: TimeInterval = 137   // 2:17

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("RUNNING")
                .font(Theme.mono(12, .bold))
                .tracking(4)
                .foregroundStyle(Theme.dim)

            HStack(spacing: 12) {
                AppTile(app: app, size: 30)
                Text(app.name).font(Theme.mono(26, .bold))
            }
            .foregroundStyle(Theme.fg)
            .padding(.top, 6)

            Text(clock(remaining))
                .font(Theme.mono(76, .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.fg)
                .padding(.top, 24)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Theme.faint)
                    Rectangle().fill(Theme.fg).frame(width: geo.size.width * 0.76)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 40)
            .padding(.top, 28)

            Text("the app is open. when this hits zero it locks again.")
                .font(Theme.mono(12))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 40)

            Spacer()

            Text("END RUN NOW")
                .font(Theme.mono(15, .semibold))
                .foregroundStyle(Theme.fg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.fg, lineWidth: 1.2))
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
        .screenBackground()
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%01d:%02d", s / 60, s % 60)
    }
}

// demo of the commitment lock control for the "stick to it" frame
struct LockSettingsDemo: View {
    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 700
            let colW = min(geo.size.width - 48, 620)

            VStack(spacing: 0) {
                HStack {
                    Text("SETTINGS")
                        .font(Theme.mono(wide ? 22 : 18, .bold)).tracking(3)
                        .foregroundStyle(Theme.fg)
                    Spacer()
                    Text("DONE").font(Theme.mono(14, .semibold)).foregroundStyle(Theme.fg)
                }
                .frame(width: colW)
                .padding(.top, wide ? 40 : 14)
                .padding(.bottom, wide ? 40 : 36)

                VStack(alignment: .leading, spacing: 26) {
                    section("THEME") {
                        AnyView(picker(["SYSTEM", "LIGHT", "DARK"], onIndex: 0))
                    }
                    section("RUNS") {
                        AnyView(picker(["SHARED POOL", "PER APP"], onIndex: 0))
                    }
                    section("LOCK SETTINGS") {
                        AnyView(VStack(alignment: .leading, spacing: 14) {
                            lockPicker
                            Text("locked for 7 days. you can make limits stricter, never looser.")
                                .font(Theme.mono(12))
                                .foregroundStyle(Theme.dim)
                                .fixedSize(horizontal: false, vertical: true)
                        })
                    }
                }
                .frame(width: colW)

                Spacer()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func section(_ label: String, @ViewBuilder _ content: () -> AnyView) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).font(Theme.mono(11, .bold)).tracking(2).foregroundStyle(Theme.dim)
            content()
        }
    }

    private func picker(_ items: [String], onIndex: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, t in
                Text(t)
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(i == onIndex ? Theme.bg : Theme.fg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 16)
                    .padding(.vertical, 13)
                    .background(i == onIndex ? Theme.fg : Color.clear)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.fg, lineWidth: 1.2))
    }

    private var lockPicker: some View {
        HStack(spacing: 0) {
            seg("OFF", on: false)
            seg("1D", on: false)
            seg("7D", on: true)
            seg("30D", on: false)
            seg("∞", on: false, big: true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.fg, lineWidth: 1.2))
    }

    private func seg(_ t: String, on: Bool, big: Bool = false) -> some View {
        Text(t)
            .font(Theme.mono(big ? 22 : 14, .semibold))
            .foregroundStyle(on ? Theme.bg : Theme.fg)
            .frame(maxWidth: .infinity)
            .frame(height: 18)
            .padding(.vertical, 13)
            .background(on ? Theme.fg : Color.clear)
    }
}
