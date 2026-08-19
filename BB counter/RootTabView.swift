import SwiftUI

/// 輸入完籌碼與盲注後的主介面：四個分頁的殼。
/// 分頁選擇刻意不持久化——牌桌上打開 App 就是要看深度，一律回儀表板。
struct RootTabView: View {
    enum Tab: Hashable {
        case dashboard
        case handLine
        case history
        case settings
    }

    let chips: Int
    @Binding var smallBlind: Int
    @Binding var bigBlind: Int
    @ObservedObject var blindSession: BlindTimerSession
    @Binding var timerEnabled: Bool
    @Binding var timerDurationSec: Int
    let chipChangeRecords: [ChipChangeRecord]
    let summary: SessionSummary
    let onClearChipHistory: () -> Void
    let onEditChips: () -> Void
    let onApplyChipChange: (Int) -> Void
    let onEditBlinds: () -> Void
    let onReset: () -> Void

    @State private var selection: Tab = .dashboard

    private var stackBB: Double {
        guard bigBlind > 0 else { return 0 }
        return Double(chips) / Double(bigBlind)
    }

    var body: some View {
        TabView(selection: $selection) {
            DashboardView(
                chips: chips,
                smallBlind: $smallBlind,
                bigBlind: $bigBlind,
                blindSession: blindSession,
                timerEnabled: $timerEnabled,
                timerDurationSec: $timerDurationSec,
                summary: summary,
                onEditChips: onEditChips,
                onApplyChipChange: onApplyChipChange,
                onEditBlinds: onEditBlinds,
                onOpenHistory: { selection = .history }
            )
            .tabItem {
                Label("tab.dashboard", systemImage: "gauge.with.needle")
            }
            .tag(Tab.dashboard)

            HandActionLineListView(
                smallBlind: smallBlind > 0 ? smallBlind : bigBlind / 2,
                bigBlind: bigBlind,
                stackBB: stackBB,
                showsDoneButton: false
            )
            .tabItem {
                Label("tab.handline", systemImage: "point.3.connected.trianglepath.dotted")
            }
            .tag(Tab.handLine)

            ChipChangeHistoryView(
                records: chipChangeRecords,
                onClear: onClearChipHistory,
                showsDoneButton: false
            )
            .tabItem {
                Label("tab.history", systemImage: "clock.arrow.circlepath")
            }
            .tag(Tab.history)

            SettingsView(
                blindSession: blindSession,
                smallBlind: $smallBlind,
                bigBlind: $bigBlind,
                timerEnabled: $timerEnabled,
                timerDurationSec: $timerDurationSec,
                chips: chips,
                onReset: onReset
            )
            .tabItem {
                Label("tab.settings", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}
