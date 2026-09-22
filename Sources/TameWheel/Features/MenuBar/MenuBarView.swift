import SwiftUI

struct MenuBarView: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "computermouse.fill")
                .font(.system(size: 16, weight: .regular))
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("小滚轮")
                    .font(.system(size: 13, weight: .semibold))
                if let hint {
                    Text(hint)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            Toggle("鼠标滚轮", isOn: Binding(
                get: { state.isScrollEnabled },
                set: { state.setScrollEnabled($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.large)
            .accessibilityIdentifier("mouseScrolling")
            .accessibilityHint(hint ?? "开启鼠标反向匀速滚动，触控板保持原样")
        }
        .frame(minHeight: 24)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 220)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var hint: String? {
        switch state.status {
        case .permissionRequired: return "需要辅助功能权限"
        case .unavailable: return "开启以重新连接"
        case .running, .paused, .preview: return nil
        }
    }
}
