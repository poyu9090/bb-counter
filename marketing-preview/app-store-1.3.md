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

## 截圖

- **iPhone 6.9"（1320×2868）**：`marketing-preview/final/01-chips.png` ~ `04-handline.png`，4 張，加了行動線那張。
- **iPad 13"（2064×2752）**：`marketing-preview/ipad/01-chips.png`、`02-blinds.png`、`03-dashboard.png`，3 張，1.3 的新畫面（原生截圖，跟舊版一樣不套外框）。

## 送審前還要人工確認的事

1. **支援 URL 與隱私權 URL**：`https://poyu9090.github.io/bb-counter/*` 目前 404（repo 是 private，GitHub Pages 沒生效）。到 GitHub 把 repo 設成 public → Settings → Pages → Source 選 `main` + `/docs`，等幾分鐘後確認這三個網址用無痕視窗打得開，再回 App Store Connect 對一次那兩欄填的網址：
   - `https://poyu9090.github.io/bb-counter/`
   - `https://poyu9090.github.io/bb-counter/app-support.html`
   - `https://poyu9090.github.io/bb-counter/privacy-policy.html`
2. **iPad 的重複分頁列**：分頁列偶爾會在畫面上下各出現一次（下面那條點不動），換頁重繪後就消失。用 10 行的原生 SwiftUI TabView 也能重現，屬於系統／模擬器層級，不是這個 App 的程式問題；沒有實機 iPad 可驗。上面那 3 張 iPad 截圖都挑了乾淨的畫面。
3. **iOS 17**：部署門檻從 18.5 降到 17.0，但本機沒有 17.x 模擬器可跑（17.5 runtime 下載到 88% 被斷線中斷）。
4. **實機跑一場牌**：Live Activity 升盲、自訂結構、暗場可讀性。
