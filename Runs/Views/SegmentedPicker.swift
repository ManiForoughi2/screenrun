import SwiftUI

struct SegmentedPicker<Value: Equatable>: View {
    let options: [(String, Value)]
    let selection: Value
    let onSelect: (Value) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let (label, value) = options[i]
                let isOn = value == selection
                Button {
                    onSelect(value)
                } label: {
                    Text(label)
                        .font(Theme.mono(13, .semibold))
                        .foregroundStyle(isOn ? Theme.bg : Theme.fg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(isOn ? Theme.fg : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Theme.fg, lineWidth: 1.2)
        )
    }
}
