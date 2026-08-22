# App Store 送審素材 — 1.3 (build 5)

App ID 6762072289 · Bundle `PaulChiang.BB-counter` · 上架語系：繁體中文、English

---

## 版本說明 What's New

### 繁體中文

```
1. 首頁改版：底部換成標準分頁列（儀表板／行動線／設定），籌碼變化直接在儀表板輸入、記錄。
2. 新增升盲預告：一眼看到下一級盲注，以及升盲後還剩幾 BB。
3. 行動線記錄升成獨立分頁，隨時開一手新的來記。
4. 盲注只問大盲；自訂盲注結構會被記住，不必每場重建。
5. 支援 iOS 17，並修正自訂結構跑完會跳回預設級距的問題。
```

### English

```
1. Redesigned home: a standard tab bar (Dashboard / Action line / Settings), with chip changes entered and logged right on the dashboard.
2. Blind level preview: see the next blind level and how many BB you'll have left after it.
3. The hand action line recorder is now its own tab.
4. Blinds only ask for the big blind, and custom blind structures are remembered between sessions.
5. Now supports iOS 17, and fixes custom structures falling back to the default levels.
```

---

## App 說明（建議更新，現行版本沒提到行動線）

### 繁體中文

```
【核心功能】
• 籌碼深度：輸入籌碼與目前大盲，立刻看到 BB 深度與健康度（健康／可打／短碼／危險）。
• 籌碼變化：贏／輸切換 + 常用面額快捷，一手打完幾秒內更新，並留下變化紀錄。
• 盲注計時：可選時長、暫停／繼續、指定接下來要跑的級別，並預告升盲後還剩幾 BB。
• 自訂盲注結構：自己建的級距會被記住，下次開 App 直接沿用。
• 行動線記錄：依德州撲克規則給出合規的動作與尺寸（Open 2～3.5bb、3-Bet／4-Bet 自動換算 bb、底池比例），記完可一鍵複製分享。
• 即時動態（Live Activity）：計時進行時，可在鎖定畫面與動態島查看升盲倒數（需於系統設定允許即時動態權限）。

【使用方式】
1) 輸入籌碼總量 → 2) 設定目前大盲 → 3) 在儀表板看 BB 深度、記錄籌碼變化、開啟升盲倒數。要記牌局過程時切到「行動線」分頁。

【隱私與資料】
BB Counter 無需註冊帳號。籌碼、盲注與計時設定都存在你的裝置上；本 App 沒有將這些資料上傳到開發者伺服器的功能。

【支援】
使用問題、建議或錯誤回報，請透過 App Store 支援頁所列的聯絡方式與我們聯繫。
```

### English

```
[Features]
• Stack depth: enter your chips and the current big blind to see your BB depth and how healthy it is.
• Chip changes: win/loss toggle plus quick amounts — update after a hand in seconds and keep a log of every change.
• Blind timer: pick a level length, pause/resume, queue the levels you'll actually play, and see how many BB you'll have left after the next raise.
• Custom blind structures: the levels you build are remembered for next time.
• Hand action line: legal actions and sizes for real Texas Hold'em (opens from 2 to 3.5bb, 3-Bet/4-Bet sizes converted to bb, pot-fraction bets postflop), ready to copy and share.
• Live Activity: track the blind countdown from the Lock Screen and Dynamic Island while the timer runs (requires Live Activities to be allowed in Settings).

[How to use]
1) Enter your chip total → 2) set the current big blind → 3) read your BB depth on the dashboard, log chip changes, and start the blind countdown. Switch to the Action line tab to record a hand.

[Privacy]
BB Counter works without an account. Chips, blinds, and timer settings stay on your device; the app has no feature that uploads them to a developer server.

[Support]
For questions, suggestions, or bug reports, use the contact details on the support page listed on the App Store.
```

---

## 截圖（已上傳到 ASC 1.3）

繁體中文與英文（美國）兩個語系各一套，**都已經傳進 App Store Connect 的 1.3 版本**：

| 語系 | iPhone 6.9"（1320×2868） | iPad 13"（2064×2752） |
| --- | --- | --- |
| 繁體中文 | `final/01-chips` ~ `04-handline` | `ipad/01-chips`、`02-blinds`、`03-dashboard` |
| 英文（美國） | `final-en/01-chips` ~ `04-handline` | `ipad-en/01-chips`、`02-blinds`、`03-dashboard` |

- 舊的 6.5" 截圖已刪除，改成「使用 6.9 吋顯示器的檔案」，所有 iPhone 尺寸都吃同一套新圖。1.2 的舊素材備份在 `archive-1.2-iphone65/`、`archive-1.2-en/`。
- **截圖不能帶 alpha**：PIL 產出的 PNG 預設是 RGBA，傳上去 ASC 會顯示紅色錯誤方塊。`generate_preview_assets.py` 現在存檔前會 `convert("RGB")`；自己補圖時記得也要壓平。

## 送審前的狀態

**已完成**

- 支援頁與隱私權頁：repo 轉 public、開啟 GitHub Pages（main + `/docs`），三個網址都回 200；ASC 的支援 URL 已經是 `https://poyu9090.github.io/bb-counter/app-support.html`。
- ASC 1.3 版本已建立，繁中／英文兩套截圖（iPhone 6.9" 各 4 張、iPad 13" 各 3 張）都上傳完成，舊的 6.5" 素材已清掉改為沿用 6.9"。
- 兩個語系的「此版本的新增功能」已填入並儲存。
- iOS 17.5 模擬器實測：單元 + UI 測試全過（18.5 也重跑過，26.5 手動走過主流程）。

**還沒做（需要你）**

1. **上傳 build**：1.3 (5) 還沒 Archive 上傳到 App Store Connect。沒有 build 就送不了審——這步要你的簽章與 ASC 帳號。
2. **年齡分級問卷**：ASC 橫幅提示「需回覆社群媒體的新年齡分級問題」，在「App 資訊」頁回答。
3. **App 說明**：現行描述仍沒提到行動線，上面有寫好的新版可直接貼。
4. **實機跑一場牌**：Live Activity 升盲、自訂盲注結構、暗場可讀性。

**已知但不影響送審**

- iPad 上分頁列偶爾會上下各出現一次（下面那條點不動），換頁重繪就消失。用 10 行的原生 SwiftUI TabView 也能重現，屬系統／模擬器層級；沒有實機 iPad 可驗，上傳的 iPad 截圖都挑了乾淨的畫面。
