# 商業模式：結論與實作計畫

> 這份是把先前討論定下來的結論寫成檔案，免得只留在對話裡。**目前一行程式都還沒寫**，因為前提條件還沒到（見最後一節）。

## 結論一：不放廣告

| 理由 | 說明 |
| --- | --- |
| 使用情境衝突 | 使用者是在牌桌上、手機放檯面、幾秒內要看完數字。插頁或影片＝牌局中被打斷，是最容易一星＋刪除的形態 |
| 隱私定位會賠掉 | 現在 `PrivacyInfo.xcprivacy` 宣告不收集資料、不追蹤。接廣告要加 ATT 彈窗、改隱私標籤、補第三方 SDK 清單 |
| 廣告庫存有風險 | 撲克類會吃到真錢博弈投放，跟現在的 4+ 分級衝突，可能被迫拉到 17+，傷 ASO |

真要放，唯一可接受的位置是**離開牌局後的結算頁**，且要能付費移除。但以目前量級，收入低於改隱私標籤的麻煩。

## 結論二：買斷優於訂閱

工具型、無後端、沒有持續產出的內容 → 訂閱說服力弱（使用者會問「月費換到什麼」）。**一次解鎖 US$4.99 / NT$150** 的轉換率會明顯高於 $2.99/月，也不用管 churn、退訂、寬限期。

訂閱留到真的有持續成本時再說（iCloud 同步、跨裝置、AI 手牌分析）。

## 功能怎麼切

| 免費（獲客核心，絕不鎖） | Pro（會累積的東西） |
| --- | --- |
| BB 深度、健康度 | 多場次紀錄與統計：每場輸贏、時長、BB/hr、走勢 |
| 籌碼加減與記錄 | 自訂盲注結構無限組 ＋ 匯出／匯入（免費限 1 組） |
| 盲注計時 + Live Activity | 行動線無限保存、標籤、批次匯出（免費限最近 5 手） |
| 行動線基本記錄 | **All-in / Push-Fold 範圍表** |
| | Apple Watch、主題配色 |

鎖住核心＝沒人留下來。付費點全部押在「用久了才會痛」的地方。

## Paywall 觸發時機

不要在首次啟動擋。三個「已經用出價值」的時刻：

1. 一場結束後（記了 ≥3 筆籌碼變化）→「這場的走勢與 BB/hr」
2. 建立第 2 組自訂盲注結構時
3. 行動線存到第 6 手時

## 怎麼加（實作規格）

**StoreKit 2，非消耗性項目，無後端、無收據驗證伺服器。**

1. **ASC**：App 內購買項目 → 非消耗性 → Product ID `PaulChiang.BB-counter.pro`，價格 Tier 5（US$4.99），六個語系的顯示名稱與說明
2. **`ProStore.swift`**（新檔，~120 行）
   - `@Observable final class ProStore`：`products`、`isPro`、`purchase()`、`restore()`
   - 用 `Product.products(for:)` 取商品、`Transaction.currentEntitlements` 判斷是否已購買、`Transaction.updates` 監聽（含家庭共享與退款）
   - `isPro` 用 `@AppStorage` 快取一份，離線與啟動瞬間也讀得到
3. **`PaywallView.swift`**（新檔，~150 行）：一頁式，四個 Pro 功能條列 + 價格 + 購買 + 還原購買 + 隱私／條款連結（Apple 必要）
4. **鎖點**：`ChipChangeHistoryView`（統計區）、`TimerConfigSheet`（第 2 組結構）、`HandActionLineListView`（第 6 手）
5. **在地化**：6 個語系各約 12 個新 key
6. **埋點**：`paywall_shown(trigger:)`、`purchase_started`、`purchase_completed`、`purchase_failed(reason:)`、`restore_completed` —— 事件名先進 `AnalyticsEvent`
7. **測試**：`ProStore` 的 entitlement 判斷用 StoreKit Testing（`.storekit` 設定檔）跑，不需要真的付款

工作量估：**一個完整工作段落**（不含 ASC 後台設定與截圖）。

## 但先別做——前提條件

以目前 **每月約 35 次下載**：

- 就算 Pro 轉換率 4%（工具型偏樂觀），也只有**每月 1～2 筆、約 US$7**
- 寫 StoreKit + Paywall 的時間，拿去做成長（義大利文、關鍵字、站外流量）的期望值高得多

**動手的門檻：**

| 指標 | 門檻 | 現況 |
| --- | --- | --- |
| 月下載 | ≥ 500 | ~35 |
| `dashboard_shown / app_opened` | ≥ 50% | 埋點剛上，還沒數據 |
| All-in 假門 CTR | ≥ 15% | 假門已在 1.5 重新打開，等數據 |

達到門檻前，商業化的正確動作是**把埋點數據養出來**，尤其是假門 CTR——它直接決定第一個 Pro 功能該做哪一個。
