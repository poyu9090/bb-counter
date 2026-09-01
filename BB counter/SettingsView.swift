import SwiftUI

/// 設定分頁：計時器設定入口、重置、版本資訊。
/// 重置從底部固定列搬來這裡——一場牌局頂多按一次，不該長期佔著隨手可及的位置。
struct SettingsView: View {
    @ObservedObject var blindSession: BlindTimerSession
    @Binding var smallBlind: Int
    @Binding var bigBlind: Int
    @Binding var timerEnabled: Bool
    @Binding var timerDurationSec: Int
    let chips: Int
    let onReset: () -> Void

    @State private var showTimerSheet: Bool = false
    @State private var showResetConfirmation: Bool = false
    @State private var showAnalytics: Bool = false
    @State private var analyticsSnapshot: AnalyticsStore.Snapshot?

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        blindSession.prepareTimerSheetDefaults(bigBlind: bigBlind)
                        showTimerSheet = true
                    } label: {
                        Label("settings.timer_row", systemImage: "timer")
                            .foregroundStyle(Theme.primaryText)
                    }
                    .accessibilityIdentifier("settings.timer")
                } header: {
                    Text("timer.title")
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("action.reset", systemImage: "arrow.counterclockwise")
                    }
                    .accessibilityIdentifier("settings.reset")
                } footer: {
                    Text("settings.reset_footer")
                }

                Section {
                    LabeledContent("settings.version", value: versionText)
                        .foregroundStyle(Theme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // List 的列預設不吃手勢，要先給它一塊可命中的形狀。
                        .contentShape(Rectangle())
                        // 長按版本列＝開發者的埋點診斷頁，一般使用者不會誤觸。
                        .onLongPressGesture(minimumDuration: 1) {
                            analyticsSnapshot = AppAnalytics.snapshot
                            showAnalytics = true
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(Text("tab.settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showAnalytics) {
            if let analyticsSnapshot {
                AnalyticsDebugView(snapshot: analyticsSnapshot)
            }
        }
        .sheet(isPresented: $showTimerSheet) {
            TimerConfigLauncher(
                isPresented: $showTimerSheet,
                blindSession: blindSession,
                smallBlind: $smallBlind,
                bigBlind: $bigBlind,
                timerEnabled: $timerEnabled,
                timerDurationSec: $timerDurationSec,
                chips: chips
            )
        }
        .sheet(isPresented: $showResetConfirmation) {
            ResetConfirmationSheet(
                isPresented: $showResetConfirmation,
                onConfirm: onReset
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}
