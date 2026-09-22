import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            HStack(spacing: 10) {
                Image(systemName: "hand.draw").font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text("触控板保持原样").font(.subheadline.weight(.semibold))
                    Text("方向、速度与惯性，交还系统。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))

            ScrollSettingsView(settings: $state.settings)
                .disabled(!state.settings.isEnabled)

            Divider()
            serviceStatus
        }
        .padding(24)
        .frame(width: 380, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .tint(.accentColor)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "computermouse.fill")
                .font(.system(size: 25, weight: .medium))
                .frame(width: 44, height: 48)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("ScrollMate").font(.system(size: 21, weight: .semibold, design: .rounded))
                Text("让鼠标回到熟悉的手感")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Menu {
                Toggle("启用鼠标调校", isOn: $state.settings.isEnabled)
                Button("恢复默认设置", action: state.restoreDefaults)
                Button("重新连接滚动服务", action: state.restart)
                Divider()
                Button("退出 ScrollMate") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel("更多操作")
            .help("暂停、恢复默认或退出")
        }
    }

    private var serviceStatus: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Circle().fill(statusColor).frame(width: 7, height: 7)
                Text(state.status.title).font(.subheadline.weight(.medium))
                Spacer()
                if state.status == .running || state.status == .paused {
                    Button(state.settings.isEnabled ? "暂停" : "继续") {
                        state.settings.isEnabled.toggle()
                    }
                    .buttonStyle(.borderless)
                }
            }
            if state.status == .permissionRequired {
                Text("允许 ScrollMate 调整鼠标滚轮。授权后会自动启用。")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                permissionButton
            } else if state.status == .unavailable {
                Text("请检查辅助功能授权，或在更多操作中重新连接。")
                    .font(.caption).foregroundStyle(.secondary)
            } else if state.status == .preview {
                Text("仅预览外观，不处理系统输入。")
                    .font(.caption).foregroundStyle(.secondary)
            } else if state.status == .paused {
                Text("鼠标与触控板均使用系统设置。")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text(state.activity).font(.caption).foregroundStyle(.secondary)
                if state.usesCompatibilityStep && state.settings.scrollingMode == .fixedStep {
                    Text("当前鼠标使用兼容匀速步长")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var permissionButton: some View {
        if #available(macOS 26.0, *) {
            Button("打开辅助功能设置", action: state.requestAccessibility)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        } else {
            Button("打开辅助功能设置", action: state.requestAccessibility)
                .buttonStyle(.borderedProminent)
        }
    }

    private var statusColor: Color {
        switch state.status {
        case .running: return .green
        case .permissionRequired, .unavailable: return .orange
        case .paused, .preview: return .secondary
        }
    }
}
