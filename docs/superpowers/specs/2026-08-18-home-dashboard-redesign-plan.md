# 首頁儀表板改版 — 實作計畫

對應設計：`2026-08-18-home-dashboard-redesign-design.md`

分四個階段，每階段結束時建置與測試都要是綠的，各自成一個 commit。任何階段做不完都可以停在那裡，App 仍是可用狀態。

## Phase 0 — 先把計算邏輯抽出 View

現在本場變化與升盲後 BB 的計算都埋在 View 的 computed property 裡，無法測試。先抽再改 UI。

**新增**

- `SessionSummary.swift`
  - `startChips`：讀 `sessionStartChips`；缺值時取最早一筆 `chipChangeRecords.previousChips` 回推；無紀錄時等於目前籌碼
  - `delta`：目前籌碼 − 起始籌碼
  - `sparkline`：起始值 ＋ 最近 8 筆的籌碼序列
- `BlindOutlook.swift`
  - `nextLevel`：走 `effectiveProgression()`，已是最後一級回 nil
  - `stackAfterNextLevel`：目前籌碼 ÷ 下一級大盲，無下一級回 nil
  - `healthTier`：沿用現有色階分級

**測試**

- 本場變化：起始 30,000 → 34,000 得 +4,000；改總額後仍正確；舊資料回推；無紀錄回 0
- 升盲後 BB：一般級距、自訂結構、最後一級回 nil

**驗收**：單元測試全綠，UI 完全沒動。

## Phase 1 — 換上 Tab 殼

**新增** `RootTabView.swift`：判斷「仍在輸入流程（onboarding／籌碼／盲注）」或「已進入 Tab」，後者顯示四個分頁。

**這階段各分頁先掛既有內容**，不改內部：

- 儀表板 → 暫時掛現有 `ResultView`（去掉底部固定列）
- 行動線 → `HandActionLineSheet` 的內容
- 紀錄 → `ChipChangeHistorySheet` 的內容
- 設定 → 計時器設定入口 ＋ 重置 ＋ 關於

**同步調整**

- `ContentView` 的 `step` 縮減為只管輸入流程
- 分頁識別碼：`tab.dashboard`／`tab.handline`／`tab.history`／`tab.settings`
- 改寫兩個既有 UI 測試（它們斷言的底部按鈕已不存在）

**驗收**：四個分頁都到得了、首次啟動流程與冷啟動還原都正常、UI 測試綠。

## Phase 2 — 儀表板三張卡

**新增**

- `DashboardView.swift`：只負責組三張卡與 Live Activity 同步
- `StackStatusCard.swift`：BB 大數字 ＋ 健康徽章 ＋ 籌碼／盲注行（各自可點）
- `ChipChangeCard.swift`：標題列（含本場變化）＋ 贏／輸切換 ＋ 輸入 ＋ 記錄 ＋ 快捷 1k/5k/10k ＋ 改總額 ＋ 迷你長條圖 ＋ 歷史入口
- `BlindTimerCard.swift`：倒數、進度條、下一級、升盲後 BB、暫停／繼續

**退場**：`ResultView` 由 `DashboardView` 取代；`ChipQuickAdjustSheet` 併入卡片（改總額仍走 `ChipsInputView`）。

**行為細節**

- 快捷鍵填入輸入框、可累加；記錄才寫入並觸發 `.success` haptic
- 「輸」超過現有籌碼於記錄當下夾到 0
- 升盲當下觸發 `.warning` haptic

**驗收**：主流程 UI 測試（記一筆贏 6,500 → BB 與本場同步更新）、模擬器實走一輪。

## Phase 3 — 邊界情況與收尾

- 尚未設盲注、籌碼歸零、計時器關閉、已是最後一級的各種顯示
- 設定分頁補齊：重置確認流程、關於
- 在地化字串新增並確認 en／zh-Hant key 對齊
- 全測試 ＋ 模擬器驗證 ＋ 放大字級與 iPad 版面檢查

**驗收**：全部測試綠，手動驗收清單走過一遍。

## Phase 4 — 視覺層（選配，另開一輪）

用 `ios-hig-design` 定色彩、字級、間距、SF Symbols 與無障礙規範後調整，完成再用 `swiftui-pro` 審程式。這階段不改行為。

## 已知風險

- `ResultView` 目前掛著一整組 Live Activity 的 `onChange`，搬進 `DashboardView` 時要確認差異推送節流仍生效
- `ContentLifecycleModifier` 依賴 `step`，Tab 化後它的職責要重新界定，別讓計時器 tick 與場景切換的處理漏掉
- 兩個既有 UI 測試會在 Phase 1 短暫變紅，該階段結束前必須修好
