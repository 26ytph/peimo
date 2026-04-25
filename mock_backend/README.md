# 朵朵 Cloud Hub — Mock Backend

一個極簡的 FastAPI mock server，提供 App 串接前的測試資料。
**沒有資料庫**，所有資料都在記憶體中（重啟後重置）。

## 啟動

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

啟動後可開啟：
- API 文件 (Swagger UI)：http://localhost:8000/docs
- 健康檢查：http://localhost:8000/health

## API 一覽

| Method | Path | 說明 |
|---|---|---|
| GET  | `/health` | 健康檢查 |
| GET  | `/youth/me` | 取得目前民眾個人檔案 |
| GET  | `/resources` | 取得所有資源卡片（可用 `?category=創業` 過濾）|
| POST | `/resources/{id}/swipe` | 對卡片做 like / pass |
| GET  | `/resources/liked` | 取得我按讚的卡片 |
| GET  | `/counselors` | 諮商師清單 |
| GET  | `/appointments` | 諮商師：查看新預約 |
| GET  | `/cases` | 諮商師：個案追蹤清單 |
| POST | `/cases/{id}/tags` | 替個案加標籤 |
| POST | `/cases/{id}/recommend` | 推薦資源給個案 |
| POST | `/chat/ai` | 與朵朵 AI 對話（回傳 mock reply）|
| POST | `/chat/counselor` | 傳訊息給諮商師（回傳 mock reply）|

## 之後串接真後端

請將 `app/data.py` 中的 in-memory store 換成資料庫存取，或把 `app/routes/*.py` 中的 handler 替換為對外部服務的呼叫即可。所有 schema 都集中在 `app/schemas.py`，與前端 Swift 的 `CloudModels.swift` 對齊。
