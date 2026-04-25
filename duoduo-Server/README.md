# 朵朵 DuoDuo — AI 職涯路徑規劃 Backend

為台北青年打造的 AI 職涯規劃平台後端服務。透過 Gemini LLM 生成個人化職涯路徑，並以 RAG 技術整合台北市政府公開資源（青年局活動、創業補助、數位課程等）提供精準推薦。

## 產品概覽

DuoDuo 服務兩大角色：**青年（民眾）** 與 **諮商師**，透過 AI 驅動的資源媒合與職涯規劃，協助台北青年探索就業、創業、進修等方向。

### 青年端功能

| 功能模組 | 說明 |
|----------|------|
| 資源卡片 | 瀏覽政策資源，左滑（捨棄）/ 右滑（按讚），可依標籤篩選，回顧已按讚項目 |
| 職涯路徑 | AI 生成多階段職涯規劃，每階段含標題、內容說明與對應資源 |
| 智慧問答 | 24 小時 AI Chatbot，可切換 AI 模式與真人諮商師模式 |
| 個人資料 | 背景建模（年齡、學歷、何倫碼、技能、興趣等），支援技能落差檢測 |
| 資源申請 | 線上申請資源並追蹤申請狀態（申請中 / 報名成功） |

### 諮商師端功能

| 功能模組 | 說明 |
|----------|------|
| 預約管理 | 查看新個案預約，檢視個案資料與描述 |
| 個案追蹤 | 標籤分類、資源推薦、近況追蹤 |
| 配對系統 | 青年申請配對 → 諮商師確認排程 → 諮商中 |

### 數據回饋機制

- **青年需求熱力圖**：統計資源卡片右滑（按讚）/ 左滑（捨棄）次數，產生需求 heatmap
- **關鍵字趨勢分析**：提取 Chatbot 對話中高頻煩惱關鍵字（面試焦慮、寫營運計畫書、非本科轉職等），輔助青年局政策規劃

## 技術棧

| 層級 | 技術 |
|------|------|
| 後端框架 | FastAPI + Python 3.11 |
| LLM | Google Gemini 2.5 Flash |
| Embedding | Gemini Embedding API (`gemini-embedding-001`) |
| 向量資料庫 | ChromaDB（HTTP client 連線） |
| 關聯式資料庫 | PostgreSQL 15 + SQLAlchemy 2.0（async） |
| 爬蟲 | Requests + BeautifulSoup4 |
| 資料增強 | Gemini LLM 自動產生標題、摘要、標籤 |
| 排程 | APScheduler（每 24 小時） |
| 容器化 | Docker + docker-compose |

## 專案結構

```
.
├── backend/
│   ├── main.py                    # FastAPI 入口 + lifespan 自動建表
│   ├── config.py                  # pydantic BaseSettings 環境變數管理
│   ├── db.py                      # async SQLAlchemy engine + session dependency
│   ├── models/
│   │   ├── base.py                # SQLAlchemy DeclarativeBase
│   │   ├── user.py                # User（帳號、角色、基本資訊）
│   │   ├── profile.py             # CitizenProfile（含 career_path）/ CounselorProfile
│   │   ├── resource.py            # Resource / ResourceStatistics / KeywordTrend
│   │   ├── interaction.py         # Appointment / CounselorAssignment / ResourceSwipe / Recommendation
│   │   ├── chat.py                # ChatSession / ChatMessage
│   │   └── case.py                # CaseRecord / CaseTag / CaseTagLink
│   ├── routers/
│   │   ├── auth.py                # POST /auth/login
│   │   ├── users.py               # /users CRUD
│   │   ├── youth.py               # /youth/me 青年個人檔案
│   │   ├── resources_crud.py      # /admin/resources CRUD
│   │   ├── resource.py            # GET /resources — RAG 語意搜尋
│   │   ├── resource_interactions.py # 資源瀏覽 / 滑動 / 申請
│   │   ├── counselors.py          # 諮商師列表 / 配對 / 預約
│   │   ├── case_records.py        # /case-records CRUD
│   │   ├── case_management.py     # 個案標籤 / 資源推薦
│   │   ├── chat_sessions.py       # AI / 諮商師聊天
│   │   └── path.py                # POST /path/generate — 多階段職涯路徑
│   ├── services/
│   │   ├── llm.py                 # Gemini API 封裝（路徑生成 / 對話 / 複雜度評估）
│   │   └── rag.py                 # ChromaDB 向量查詢（Gemini Embedding）
│   ├── Dockerfile
│   └── requirements.txt
│
├── crawler/
│   ├── scheduler.py               # APScheduler 每 24h 排程
│   ├── ingest.py                  # 爬取 → LLM 增強 → 寫入 ChromaDB + PostgreSQL
│   ├── llm_enricher.py            # Gemini LLM 資料增強（標題 / 摘要 / 標籤）
│   ├── chromadb_client.py         # ChromaDB HTTP 連線（Gemini Embedding）
│   ├── pg_client.py               # PostgreSQL 同步寫入（psycopg2）
│   ├── spiders/
│   │   ├── policy_data.py         # 台北市青年補助政策（靜態資料，13 項）
│   │   ├── youth_bureau.py        # 青年局公告（Nuxt payload 端點）
│   │   ├── startup_taipei.py      # 創業台北新聞 / 活動 / 課程
│   │   ├── class_tcyd.py          # 青年局課程活動報名系統
│   │   ├── career_platform.py     # 職涯發展平台（SPA，部分受限）
│   │   └── open_taipei.py         # Open Taipei 開放資料 API（待填入 dataset ID）
│   ├── Dockerfile
│   └── requirements.txt
│
├── mock_backend/                  # iOS 前端開發用的 in-memory mock server
│   └── app/
│       ├── main.py                # FastAPI 入口（24 個模擬端點）
│       ├── schemas.py             # Pydantic schema（對齊 iOS CloudModels.swift）
│       └── data.py                # 靜態假資料
│
├── docker-compose.yml             # postgres + chromadb + backend + crawler
└── .env.example                   # 環境變數範本
```

## 資料庫架構

### ER Diagram

```
users
├── citizen_profiles (1:1)
│   ├── career_path (JSON)         # LLM 生成的多階段職涯規劃
│   ├── appointments (1:N)
│   ├── counselor_assignments (1:N)
│   ├── resource_swipes (1:N)
│   ├── recommendations (1:N)
│   ├── chat_sessions (1:N)
│   └── case_records (1:N)
├── counselor_profiles (1:1)
│   ├── appointments (1:N)
│   ├── counselor_assignments (1:N)
│   ├── recommendations (1:N)
│   ├── chat_sessions (1:N)
│   └── case_records (1:N)
resources (title + source UNIQUE)
├── resource_statistics (1:1)
├── resource_swipes (1:N)
└── recommendations (1:N)
```

### 資料表一覽（15 張）

| 表名 | 說明 |
|------|------|
| `users` | 使用者帳號（account / password_hash / role / name / email / avatar_url） |
| `citizen_profiles` | 青年檔案（age / location / school / skills / interests / holland codes / career_path） |
| `counselor_profiles` | 諮商師檔案（title / specialty / introduction / status / years_experience） |
| `resources` | 政策資源（title / content / tags / source / url），與 RAG 格式對齊 |
| `resource_statistics` | 資源統計（like / dislike / save / view count） |
| `resource_swipes` | 卡片滑動紀錄（citizen + resource + action: like / dislike / save / confirmed） |
| `recommendations` | 推薦紀錄（AI 或諮商師推薦資源給青年） |
| `appointments` | 預約紀錄（citizen ↔ counselor） |
| `counselor_assignments` | 諮商師配對（citizen ↔ counselor，active / scheduled / ended） |
| `chat_sessions` | 對話 session（ai / counselor 模式） |
| `chat_messages` | 對話訊息（sender_type: citizen / counselor / ai） |
| `case_records` | 個案紀錄（summary / status / counselor_note） |
| `case_tags` | 個案標籤（name） |
| `case_tag_links` | 個案標籤關聯（case_record ↔ tag，多對多） |
| `keyword_trends` | 關鍵字趨勢（keyword / count / source） |

## 系統架構

```
┌──────────────┐     ┌──────────────┐
│   Frontend   │────▶│   FastAPI    │
│  (iOS App)   │◀────│   Backend    │
└──────────────┘     └──────┬───────┘
                            │
                  ┌─────────┼─────────┐
                  ▼         ▼         ▼
            ┌──────────┐ ┌──────┐ ┌────────┐
            │ ChromaDB │ │  PG  │ │ Gemini │
            │  (RAG)   │ │  DB  │ │  LLM   │
            └────▲─────┘ └──▲───┘ └────────┘
                 │          │
            ┌────┴──────────┴──┐
            │     Crawler      │  ← APScheduler 每 24h
            │     Pipeline     │
            └──────────────────┘
                 │
    ┌────────────┼────────────────────┐
    ▼            ▼            ▼       ▼
 青年局       創業台北     青年職發   政策資料
 公告         新聞/課程    中心課程   (靜態)
```

### 資料流

1. **Crawler** 定時從 6 個資料來源爬取內容
2. **LLM Enricher** 用 Gemini 為每筆資料產生標題、摘要與分類標籤
3. **雙寫入**：同時寫入 ChromaDB（向量搜尋用）與 PostgreSQL（卡片瀏覽 / 互動用）
4. **Backend** 收到使用者請求時：
   - RAG 語意搜尋 → ChromaDB（Gemini Embedding）
   - 資源瀏覽 / 滑動 / 申請 → PostgreSQL
5. **Gemini LLM** 結合 RAG 結果生成個人化回覆與多階段職涯路徑

### 爬蟲技術細節

| 爬蟲 | 技術 | 說明 |
|------|------|------|
| `youth_bureau.py` | Nuxt `_payload.json` | youth.gov.taipei 為 Vue.js SPA，透過 Nuxt 預渲染資料端點取得 |
| `startup_taipei.py` | requests + BS4 | 傳統 server-rendered，從 `#mainContent` 提取，過濾分類導覽連結 |
| `class_tcyd.py` | requests + BS4 | 從列表頁直接提取課程資訊（detail 頁僅有註冊系統公告） |
| `career_platform.py` | requests + BS4 | tpyd.104.com.tw 為 React SPA，目前僅能取有限靜態內容 |
| `policy_data.py` | 靜態資料 | 13 項手動整理的台北市青年政策 |
| `open_taipei.py` | REST API | 待填入正確 dataset ID |

### LLM 資料增強

爬蟲取得的原始資料經 Gemini 2.5 Flash 處理後產生：
- **title** — 簡潔標題（20 字以內）
- **summary** — 結構化摘要（100-200 字），保留日期、費用、報名方式等關鍵資訊
- **tags** — 從預定義類別中選取標籤（創業、就業、職涯、培訓課程、補助、貸款、實習、志工、國際交流、市集、諮詢輔導、政策公告、活動、青年住宅、心理健康）

## API 端點

### 使用者管理

| Method | Path | 說明 |
|--------|------|------|
| POST | `/auth/login` | 帳號密碼登入 |
| GET | `/users` | 列出所有使用者 |
| GET | `/users/{user_id}` | 查詢單一使用者 |
| POST | `/users` | 建立使用者（citizen / counselor / admin） |
| PATCH | `/users/{user_id}` | 更新使用者 |
| DELETE | `/users/{user_id}` | 刪除使用者 |

### 青年個人檔案

| Method | Path | 說明 |
|--------|------|------|
| GET | `/youth/me?user_id=` | 取得青年檔案（含 career_path） |
| PATCH | `/youth/me?user_id=` | 更新青年檔案 |
| POST | `/youth/me/avatar?user_id=` | 上傳頭像 |

### 資源管理（後台）

| Method | Path | 說明 |
|--------|------|------|
| GET | `/admin/resources` | 列出所有資源 |
| GET | `/admin/resources/{id}` | 查詢單一資源 |
| POST | `/admin/resources` | 新增資源（title / content / tags / source / url） |
| PATCH | `/admin/resources/{id}` | 更新資源 |
| DELETE | `/admin/resources/{id}` | 刪除資源 |

### 資源互動（前台）

| Method | Path | 說明 |
|--------|------|------|
| GET | `/resources?query=` | RAG 語意搜尋資源 |
| GET | `/resources/browse?tag=` | 瀏覽資源卡片（可依標籤篩選） |
| GET | `/resources/liked?user_id=` | 已按讚的資源 |
| POST | `/resources/{id}/swipe?user_id=` | 滑動卡片（left / right） |
| POST | `/resources/{id}/apply?user_id=` | 申請資源 |
| POST | `/resources/{id}/confirm?user_id=` | 確認報名成功 |
| GET | `/resources/applications?user_id=` | 查詢所有申請狀態 |

### AI 功能

| Method | Path | 說明 |
|--------|------|------|
| POST | `/path/generate` | AI 生成多階段職涯路徑（存入 citizen_profile.career_path） |
| POST | `/chat/message` | AI 諮商對話（RAG 資源注入 + 真人轉介判斷） |

### 聊天系統

| Method | Path | 說明 |
|--------|------|------|
| GET | `/chat/ai?user_id=` | 取得 AI 對話歷史 |
| POST | `/chat/ai?user_id=` | 發送 AI 對話訊息（含 RAG） |
| GET | `/chat/counselor?user_id=` | 取得諮商師對話歷史 |
| POST | `/chat/counselor?user_id=` | 發送諮商師對話訊息 |

### 諮商師 + 配對

| Method | Path | 說明 |
|--------|------|------|
| GET | `/counselors` | 列出所有諮商師 |
| POST | `/counselors/{id}/apply?user_id=` | 申請配對諮商師 |
| POST | `/counselors/{id}/schedule?user_id=` | 諮商師確認排程 |
| GET | `/counselors/match?user_id=` | 查詢目前配對狀態 |
| DELETE | `/counselors/match?user_id=` | 取消配對 |
| GET | `/appointments?user_id=` | 列出預約 |

### 個案管理

| Method | Path | 說明 |
|--------|------|------|
| GET | `/case-records` | 列出個案紀錄 |
| GET | `/case-records/{id}` | 查詢單一個案 |
| POST | `/case-records` | 建立個案紀錄 |
| PATCH | `/case-records/{id}` | 更新個案紀錄 |
| DELETE | `/case-records/{id}` | 刪除個案紀錄 |
| GET | `/case-tags` | 列出所有個案標籤 |
| POST | `/cases/{id}/tags` | 為個案加上標籤 |
| POST | `/cases/{id}/recommend` | 為個案推薦資源 |

### 系統

| Method | Path | 說明 |
|--------|------|------|
| GET | `/health` | 健康檢查 |

## 資料來源

| 爬蟲 | 來源 | 內容類型 | 筆數 |
|------|------|----------|------|
| `policy_data.py` | 靜態資料 | 13 項台北市青年補助 / 貸款 / 實習政策 | ~13 |
| `youth_bureau.py` | youth.gov.taipei | 青年局簡介、組織、業務職掌 | ~5 |
| `startup_taipei.py` | startup.taipei | 創業新聞、活動、初階 / 進階課程 | ~48 |
| `class_tcyd.py` | class.tcyd.gov.taipei | 青年學院課程（運動力、手作力、旅遊力等） | ~4 |
| `career_platform.py` | tpyd.104.com.tw | 職涯諮詢、創業輔導、實習媒合（SPA 受限） | 0 |
| `open_taipei.py` | data.taipei API | 開放資料集（待填入 dataset ID） | 0 |

## 本地開發

```bash
cp .env.example .env
# 編輯 .env，填入 GEMINI_API_KEY

docker-compose up --build
```

服務啟動後：
- Backend API：http://localhost:8080
- API 文件（Swagger）：http://localhost:8080/docs
- Health check：http://localhost:8080/health

## 環境變數

| 變數名稱 | 說明 | 預設值 |
|----------|------|--------|
| `GEMINI_API_KEY` | Google Gemini API 金鑰 | （必填） |
| `POSTGRES_PASSWORD` | PostgreSQL 密碼 | `duoduo_dev` |
| `ENVIRONMENT` | 執行環境 | `development` |

> `DATABASE_URL`、`CHROMA_HOST`、`CHROMA_PORT` 由 docker-compose 內部自動設定，不需手動配置。Crawler 與 Backend 共用同一個 PostgreSQL。

## 功能完成度

### 已完成

- [x] FastAPI 應用骨架與 lifespan 管理
- [x] 環境變數集中管理（pydantic BaseSettings）
- [x] async SQLAlchemy engine + session dependency 注入
- [x] 15 張資料表（users / profiles / resources / interactions / chat / case）
- [x] 使用者 CRUD（`/users`）
- [x] 青年個人檔案（`/youth/me`，含 career_path）
- [x] 資源後台 CRUD（`/admin/resources`，欄位對齊 RAG：title / content / tags）
- [x] 資源卡片互動（瀏覽 / 滑動 / 按讚 / 申請 / 確認）
- [x] 諮商師列表與配對系統（申請 / 排程 / 取消）
- [x] 個案紀錄 CRUD + 標籤管理 + 資源推薦
- [x] AI 聊天（RAG + Gemini LLM + 真人轉介判斷）
- [x] 諮商師聊天（訊息持久化）
- [x] 多階段職涯路徑生成（AI 規劃，存入 citizen_profile）
- [x] ChromaDB RAG 服務（Gemini Embedding 向量查詢）
- [x] 六支爬蟲 + LLM 資料增強 pipeline
- [x] 爬蟲雙寫入（ChromaDB + PostgreSQL 同步）
- [x] 爬蟲排程器（APScheduler 每 24h）
- [x] Docker + docker-compose 四服務編排

### 待完成

- [ ] **JWT 認證** — 目前用 query param user_id，需改為 JWT token 機制
- [ ] **WebSocket 即時通訊** — 目前聊天為 HTTP polling
- [ ] **數據回饋** — 資源卡片熱力圖、KeywordTrend 寫入與分析 API
- [ ] **Open Taipei dataset ID 填入**
- [ ] **Alembic 資料庫遷移** — 目前用 `create_all` 自動建表
- [ ] **單元測試與整合測試**
- [ ] **CORS / Rate limiting / 結構化 logging**
- [ ] **CI/CD pipeline**
