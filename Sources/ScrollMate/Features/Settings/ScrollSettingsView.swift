import SwiftUI

struct ScrollSettingsView: View {
    @Binding var settings: ScrollSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle(isOn: $settings.reverseMouseScrolling) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("反转滚轮方向").font(.subheadline.weight(.medium))
                    Text("仅反转鼠标的垂直滚动")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .accessibilityIdentifier("reverseScrolling")

            VStack(alignment: .leading, spacing: 10) {
                Text("滚动手感").font(.subheadline.weight(.medium))
                Picker("滚动手感", selection: $settings.scrollingMode) {
                    Text("匀速").tag(ScrollSettings.ScrollingMode.fixedStep)
                    Text("系统加速").tag(ScrollSettings.ScrollingMode.system)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("scrollMode")
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("滚动速度").font(.subheadline.weight(.medium))
                    Spacer()
                    Text(rateLabel)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .accessibilityIdentifier("scrollRate")
                }
                if settings.scrollingMode == .fixedStep {
                    Slider(value: Binding(
                        get: { Double(settings.linesPerStep) },
                        set: { settings.linesPerStep = Int($0.rounded()) }
                    ), in: 1...12, step: 1)
                    .accessibilityLabel("固定滚动行数")
                } else {
                    Slider(value: $settings.speedMultiplier, in: ScrollSettings.allowedSpeed, step: 0.25)
                        .accessibilityLabel("系统滚动速度倍率")
                }
                HStack {
                    Text("慢")
                    Spacer()
                    Text("快")
                }
                .font(.caption2).foregroundStyle(.secondary)

                Text(settings.scrollingMode == .fixedStep
                     ? "固定步长，轻滚与快滚保持一致。"
                     : "保留系统加速，按倍率调整鼠标速度。")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var rateLabel: String {
        if settings.scrollingMode == .fixedStep { return "\(settings.linesPerStep) 行" }
        return settings.speedMultiplier.formatted(.number.precision(.fractionLength(0...2))) + " ×"
    }
}
