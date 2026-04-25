# TODO

## Demo User

固定使用 `user_id`: `ed26c486-80c3-4764-b72c-80e4cb7f8642`（不做驗證）

## 民眾 Onboarding 串接流程

```
LoginView ──→ YouthLandingView ──→ RegisterView ──→ AIInterviewView ──→ AnalysisResultView
   (1)             (2)                 (3)              (4)                   (5)
     ──→ PathGeneratingView ──→ YouthTabView
              (6)                  (7)
```

### 各步驟 API 對應

| 步驟 | 畫面 | 說明 | API | 狀態 |
|------|------|------|-----|------|
| 1 | LoginView | 選擇身份 | — | ✅ |
| 2 | YouthLandingView | 歡迎頁 | — | ✅ |
| 3 | RegisterView | 填寫基本資料；上傳 CV 填入固定資料 | — | ✅ |
| 4 | AIInterviewView | 動態問答，後端根據 missing_fields 決定下一題，直到 completed=true | `POST /landing/chat` | ✅ 已串接 |
| 5 | AnalysisResultView | 顯示 AI 使用者建模（Holland、目標、成就、困境、技能、bio），使用者可編輯後確認 | `PATCH /youth/me` | ✅ 已串接 |
| 6 | PathGeneratingView | 分析動畫 → 生成職涯路徑 | `POST /path/generate` | ✅ 已串接（目前後端 500，fallback 到 mock） |
| 7 | YouthTabView | 進入主 App（Tab：資源探索 → **職涯路徑**（預設）→ 朵朵樹洞） | — | ✅ |

### `/landing/chat` 流程

1. 初始呼叫（帶 RegisterView 已填的基本資訊）→ 後端回傳 `missing_fields` + `next_question`
2. 使用者回答 → 後端萃取欄位（`extracted_fields`）→ 更新 `profile_data` → 回傳下一題
3. 重複直到 `completed: true`，此時回傳 `generated_bio` + 完整 `profile_data`
4. 後端自動將萃取結果存入 youth profile

### 進入主 App 後的 API

| 功能 | API | 狀態 |
|------|-----|------|
| 資源卡片瀏覽 | `GET /resources/browse` | ⬜ TODO |
| 資源語意搜尋 | `GET /resources?query=&n=` | ⬜ TODO |
| 滑卡 like/pass | `POST /resources/{id}/swipe` | ⬜ TODO |
| 已收藏資源 | `GET /resources/liked?user_id=` | ⬜ TODO |
| 資源申請 | `POST /resources/{id}/apply` | ⬜ TODO |
| AI 聊天 | `POST /chat/message` | ⬜ TODO |
| 諮商師列表 | `GET /counselors` | ⬜ TODO |
| 申請配對諮商師 | `POST /counselors/{id}/apply` | ⬜ TODO |
| 諮商師聊天 | `POST /chat/counselor` | ⬜ TODO |

## 已串接 API 總覽

| API | 用途 | 使用位置 |
|-----|------|---------|
| `POST /landing/chat` | 動態問答 + 萃取使用者輪廓 | `AIInterviewView` |
| `PATCH /youth/me?user_id=` | 使用者確認後儲存完整 profile | `AppState.confirmAnalysisResult()` |
| `GET /youth/me?user_id=` | 取得使用者 profile | `APIService`（備用） |
| `POST /path/generate` | 生成職涯路徑（目前後端 500） | `AppState.confirmAnalysisResult()` |

## TODO

### 後端

- [ ] **`POST /path/generate`** — 目前回傳 500 Internal Server Error，前端已串接但 fallback 到 mock
- [ ] **`PATCH /youth/me`** — 目前回傳 500，導致註冊資料無法同步，landing/chat 會重複問已填欄位
- [ ] **`PATCH /users/{id}`** — 目前回傳 500
- [ ] **認證/登入** — demo 先用固定 `user_id`
- [ ] **CV 上傳 + AI 解析** — demo 不做

### 前端

- [ ] 主 App 內所有資源/聊天/諮商師功能從 mock 切換到 APIService
