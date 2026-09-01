# 埋點：現在有什麼、怎麼接後台

## 現況（1.5 開發中）

事件全部進 `AppAnalytics.track(_:)`，做兩件事：

1. **寫進本機的 `AnalyticsStore`**——次數、首末次時間、活躍天數。不需要網路、不需要帳號。
2. **轉發給有接上的後台**——目前沒有接，所以資料完全沒有離開裝置，App 隱私標籤維持「不收集資料」。

在設定頁**長按「版本」那一列一秒**會開出 Analytics 診斷頁：漏斗、所有事件次數、安裝天數、隔天是否回訪，右上 Copy 可以整份複製走。自己實機走一輪就能確認埋點有沒有記對。

## 事件清單

檔案：`BB counter/AnalyticsEvent.swift`

| 事件 | 什麼時候送 | 參數 |
| --- | --- | --- |
| `app_opened` | 每次啟動 | — |
| `onboarding_completed` | 按下「開始使用 App」 | — |
| `chips_entered` | 首次輸入籌碼按下一步 | `method`（面額鍵／打字）、`chips_bucket` |
| `blinds_set` | 設定大盲送出 | `method`（預設／手動）、`bb_bucket` |
| `dashboard_shown` | 進到儀表板，**每次啟動只記一次** | `depth_bucket` |
| `chip_change_logged` | 按下「記錄」 | `direction`（win／loss） |
| `chip_total_edited` | 從儀表板改總額 | — |
| `history_opened` | 打開變更紀錄 | — |
| `timer_enabled` | 計時器開關打開 | — |
| `timer_started` | 設定頁按「開始」 | — |
| `timer_paused` / `timer_resumed` | 卡片上的暫停／播放 | — |
| `blind_level_up` | 盲注真的升級 | `bb_bucket` |
| `live_activity_started` / `live_activity_unavailable` | 即時動態成功／失敗 | 失敗帶 `reason` |
| `custom_structure_saved` | 存下自訂盲注結構 | `levels` |
| `hand_line_opened` / `hand_line_created` / `hand_line_action_added` / `hand_line_copied` | 行動線分頁 | 加入行動帶 `street` |
| `all_in_prompt_shown` / `all_in_prompt_tapped` | All-in 範圍假門（1.5 重新打開，深度 < 15BB 時才出現） | — |
| `session_reset` | 設定頁重設 | — |

**參數一律分桶**（`10k-50k`、`40-100bb`），不送原始籌碼與盲注數字——牌局金額是使用者的隱私，看趨勢也不需要精確值。

## 主漏斗

```
app_opened → chips_entered → blinds_set → dashboard_shown → chip_change_logged
```

`dashboard_shown` 每次啟動只記一次，所以它永遠不會超過 `app_opened`，比例可以直接讀。

## TelemetryDeck 接線狀態

| 步驟 | 狀態 |
| --- | --- |
| SPM 套件 `TelemetryDeck/SwiftSDK` 2.14.2 | ✅ 已掛在 App target |
| `AppAnalytics.telemetryDeckAppID` | ✅ 已填入 |
| `PrivacyInfo.xcprivacy` 宣告產品互動 | ✅ 已加（未連結身分、不追蹤、用途 Analytics） |
| ASC → App 隱私權 | ⏳ **1.5 送審前**再改 |

最後一項刻意留到 1.5：目前線上的 1.3 與審核中的 1.4 都**沒有**這個 SDK，現在就把商店頁改成「會收集使用資料」反而與事實不符。1.5 送審時一起更新即可——新增「使用資料 → 產品互動」，未連結身分、不用於追蹤、用途分析。

**驗證過**：模擬器啟動後可以看到 App 對 `https://nom.telemetrydeck.com/v2/` 建立連線，事件確實有送出去。

**踩過的雷**：`TelemetryDeck.signal()` 在還沒 `initialize` 之前呼叫會直接 assert 當掉。冷啟動還原進度那條路徑（`restoreResultStepIfDataIsComplete`）在第一次 layout 就會送 `dashboard_shown`，比 `.onAppear` 早，所以 `AppAnalytics.start()` 必須放在 `BB_counterApp.init()`；`forward` 另外用 `isBackendRunning` 擋一層，順序再變也只會少送、不會當掉。

**DEBUG 建置送出的訊號會被標成測試模式**，要在 TelemetryDeck 後台打開「Test mode」才看得到；正式版（TestFlight／App Store）才會進正式數據。

選 TelemetryDeck 而不是 Firebase 的理由：匿名、不需要 ATT 彈窗、SDK 很輕，隱私標籤只要多宣告一項；Firebase 會把「不收集資料」這個乾淨定位整個換掉。

## 之後要看什麼

以現在每天 1～2 次下載的量，兩週後值得看的是：

1. `dashboard_shown / app_opened`——有多少人真的把 App 用起來
2. `chip_change_logged`、`timer_started` 的絕對次數——核心功能有沒有人用
3. `hand_line_created`——行動線是不是只有你在用
4. `all_in_prompt_tapped / all_in_prompt_shown`——假門 CTR，決定第一個付費功能做什麼
