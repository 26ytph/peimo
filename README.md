<p align="center">
  <img src="https://img.shields.io/badge/SwiftUI-iOS_17+-blue?logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white" />
  <img src="https://img.shields.io/badge/AI_Powered-LLM_+_RAG-blueviolet?logo=openai&logoColor=white" />
</p>

<h1 align="center">☁️ 朵朵 Cloud Hub</h1>

<p align="center">
  <strong>讓夢想有支撐的雲</strong><br/>
  AI 驅動的青年職涯探索平台 — 用對話取代表單，用理解取代填空
</p>

<p align="center">
  <a href="#-核心特色">核心特色</a> · <a href="#-產品流程">產品流程</a> · <a href="#️-技術架構">技術架構</a> · <a href="#-快速開始">快速開始</a>
</p>

---

## 🧠 為什麼需要朵朵？

> 台灣每年有超過 30 萬名青年在職涯探索階段迷路。政府資源很多，但散落在不同網站、不同格式、不同申請流程裡。問題從來不是「資源不夠」，而是「不知道有什麼適合我」。

**朵朵**不做又一個資源列表。我們讓 AI 先理解你是誰，再幫你找到那些「原來這就是為我設計的」的機會。

---

## ✨ 核心特色

### 🎙️ AI 對話式建模

丟掉冗長的表單。朵朵用自然對話逐步認識你 — 學經歷、興趣、夢想、甚至那些你不確定怎麼說的困境。幾分鐘後，你會看到一份比你自己寫得還準的個人輪廓。

### 🃏 Tinder-style 資源探索

向右滑收藏、向左滑跳過。背後是 RAG 語意搜尋，不靠關鍵字比對，而是真正理解「這個資源適不適合這個人」。

### 🗺️ AI 職涯路徑生成

根據你的 Holland 人格類型、技能、目標，AI 生成一條分階段的職涯藍圖 — 不是「你應該當工程師」的空話，而是每個階段該做什麼、可以用什麼資源。

### 💬 朵朵樹洞

隨時和 AI 聊天問問題、整理思緒，或在準備好之後，配對真人諮商師深度諮詢。

### 👩‍⚕️ 諮商師工作台

專業諮商師可以管理個案、標記追蹤標籤、直接推薦資源給青年 — 數位化的個案管理，不再靠 Excel。

---

## 🔄 產品流程

```
  ┌─────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
  │  登入選擇 │ ──→ │ 基本資料   │ ──→ │ AI 對話   │ ──→ │ 個人輪廓   │
  │  身份角色 │     │ + CV 上傳  │     │ 逐步建模   │     │ 確認 / 編輯│
  └─────────┘     └──────────┘     └──────────┘     └──────────┘
                                                          │
                  ┌──────────────────────────────────────┘
                  ▼
  ┌──────────────────────────────────────────────────────────┐
  │                    ☁️ 朵朵主畫面                          │
  │                                                          │
  │   📋 資源探索        🗺️ 職涯路徑        💬 朵朵樹洞      │
  │   滑卡收藏資源       AI 生成藍圖        AI 聊天 / 諮商師  │
  └──────────────────────────────────────────────────────────┘
```

---

## 🏗️ 技術架構

| 層 | 技術 | 說明 |
|---|---|---|
| **iOS 前端** | SwiftUI + `@Observable` | 單一 `AppState` 驅動全畫面，螢幕流程由 enum 控制 |
| **後端 API** | FastAPI + PostgreSQL | RESTful API，LLM 整合對話式欄位萃取 |
| **AI 引擎** | GPT + RAG (ChromaDB) | 語意搜尋資源、對話建模、職涯路徑生成 |
| **部署** | Docker on Cloud | `duoduo-backend.zudo.cc` |

```
┌─────────────┐        ┌──────────────────────────────────┐
│  iOS App     │  HTTP  │  FastAPI Backend                  │
│  (SwiftUI)   │ ◄────► │                                  │
│              │        │  /landing/chat  ── LLM 萃取欄位   │
│  AppState    │        │  /path/generate ── LLM 職涯生成   │
│  APIService  │        │  /chat/message  ── RAG 語意回覆   │
│              │        │  /resources     ── ChromaDB 搜尋  │
└─────────────┘        └──────────────────────────────────┘
```

---

## 🚀 快速開始

### iOS App

```bash
open duoduo-iOS/duoduo.xcodeproj
# Xcode → Build & Run (iPhone Simulator)
```

### Mock Backend（本地開發用）

```bash
cd mock_backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
# Swagger UI → http://localhost:8000/docs
```

---

## 👥 團隊

**PEIMO 配磨** — 讓青年不再獨自面對職涯迷霧

---

<p align="center">
  <sub>Built with ☁️ and a lot of empathy.</sub>
</p>
