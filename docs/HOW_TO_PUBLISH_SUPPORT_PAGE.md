# 如何把「App 支援頁」變成公開網址

專案內已有一份單頁說明：**`docs/app-support.html`**（繁中 + 英文、深色版型，適合 BB Counter）。

**上架前請做兩件事：**

1. 用文字編輯器打開 `app-support.html`，把裡面的 **`YOUR_EMAIL@example.com`** 全部改成你的聯絡信箱。  
2. 選下面任一方式公開成 **`https://...`**，再把該網址填到 App Store Connect 的 **支援 URL**。

---

## 方式 A：Notion（最快、不必寫程式）

1. 在 Notion 新增一頁，標題例如「BB Counter 支援」。  
2. 把 `app-support.html` 裡的**文字段落**複製到 Notion（Notion 不直接吃 HTML 檔，建議手動貼上各段；或先用瀏覽器打開 HTML 再複製內容）。  
3. 右上角 **Share** → 開啟 **Share to web**（發布到網路）→ 複製公開連結。  
4. 確認用無痕視窗能打開該連結。  
5. 將此 **https** 連結填到 App Store Connect。

---

## 方式 B：Google Sites

1. 開啟 [Google Sites](https://sites.google.com/new) 建立新網站。  
2. 新增文字區塊，將 `app-support.html` 的內容依段落貼上（或參考其結構自行排版）。  
3. **Publish** → 選公開範圍 → 取得 **`https://sites.google.com/...`** 網址。  
4. 填到 App Store Connect 的支援 URL。

---

## 方式 C：GitHub Pages（適合已有 GitHub 帳號）

1. 把 `docs/app-support.html` 推上 GitHub 倉庫。  
2. 倉庫 **Settings → Pages**：  
   - Source 選 **Deploy from a branch**  
   - Branch 選 `main`（或你的預設分支）  
   - Folder 選 **`/docs`**  
3. 儲存後等待幾分鐘，Pages 網址通常為：  
   `https://<你的帳號>.github.io/<倉庫名>/app-support.html`  
4. 用瀏覽器確認可開啟後，將完整 URL 填到 App Store Connect。

若倉庫名有空格（例如本專案 `BB counter`），GitHub 網址中的路徑會依 GitHub 規則編碼，請以 Pages 設定頁顯示的網址為準。

---

## 方式 D：本機先預覽 HTML

在終端機於專案根目錄執行：

```bash
open docs/app-support.html
```

或用瀏覽器直接開該檔案檢查排版與信箱是否已改。
