import SwiftUI

/// 這台裝置上的埋點數字。長按設定頁的版本列才會出現——是給開發者看的診斷頁，
/// 所以文字刻意不做在地化，也不放進一般使用者會走到的動線。
struct AnalyticsDebugView: View {
    let snapshot: AnalyticsStore.Snapshot
    @Environment(\.dismiss) private var dismiss

    private var sortedCounts: [(String, Int)] {
        snapshot.counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Usage") {
                    row("Installed", snapshot.installDate.map { Self.dateFormatter.string(from: $0) } ?? "—")
                    row("Days since install", "\(snapshot.daysSinceInstall)")
                    row("Active days", "\(snapshot.activeDayCount)")
                    row("Came back next day", snapshot.returnedNextDay ? "yes" : "no")
                    row("Active days in first week", "\(snapshot.activeDaysInFirstWeek)")
                }

                Section("Funnel") {
                    let steps = snapshot.funnel
                    let top = steps.first?.count ?? 0
                    ForEach(steps, id: \.step) { step in
                        row(step.step, top > 0 ? "\(step.count)  (\(percent(step.count, of: top)))" : "\(step.count)")
                    }
                }

                Section("All events") {
                    if sortedCounts.isEmpty {
                        Text("Nothing recorded yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedCounts, id: \.0) { name, count in
                            row(name, "\(count)")
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Copy") { UIPasteboard.general.string = plainText }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.callout)
    }

    private func percent(_ value: Int, of total: Int) -> String {
        guard total > 0 else { return "—" }
        return String(format: "%.0f%%", Double(value) / Double(total) * 100)
    }

    private var plainText: String {
        var lines = ["install=\(snapshot.installDate.map(Self.dateFormatter.string) ?? "-")",
                     "days_since_install=\(snapshot.daysSinceInstall)",
                     "active_days=\(snapshot.activeDayCount)",
                     "returned_next_day=\(snapshot.returnedNextDay)",
                     "active_days_first_week=\(snapshot.activeDaysInFirstWeek)"]
        lines += sortedCounts.map { "\($0.0)=\($0.1)" }
        return lines.joined(separator: "\n")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}
