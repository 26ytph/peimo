# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**朵朵 Cloud Hub (duoduo)** — A youth career counseling platform with two user roles:
- **Youth (民眾)**: Browse resources via swipe cards, chat with AI/counselors, generate AI career paths, apply for resources
- **Counselor (諮商師)**: Manage appointments, track cases, tag clients, recommend resources

The repo has two components:
1. **`duoduo-iOS/`** — SwiftUI iOS app (Xcode project `duoduo.xcodeproj`)
2. **`mock_backend/`** — FastAPI mock server (in-memory, no database)

## Build & Run

### iOS App
Open `duoduo-iOS/duoduo.xcodeproj` in Xcode. Build target is `duoduo`. Tests: `duoduoTests`, `duoduoUITests`.

### Mock Backend
```bash
cd mock_backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```
Swagger UI at `http://localhost:8000/docs`.

## Architecture

### iOS App (`duoduo-iOS/duoduo/`)

- **State/AppState.swift** — Single `@Observable` class (`AppState`) holds all app state: screen flow, user profile, resources, chat messages, counselor data. Injected via SwiftUI environment. Contains mock async logic via `DispatchQueue.main.asyncAfter`.
- **Models/CloudModels.swift** — Domain models shared across the app (enums, structs for resources, profiles, chat, career paths, counselors, cases).
- **Models/MockData.swift** — In-app mock data for development without backend.
- **Network/APIService.swift** — `actor`-based singleton (`APIService.shared`) hitting the real backend at `https://duoduo-backend.zudo.cc`. Generic `request<T: Decodable>` method handles all API calls.
- **Network/APIModels.swift** — Request/response DTOs matching the backend's Pydantic schemas (snake_case fields).
- **Views/** — Split by role:
  - `Auth/` — Login, registration, AI interview, career path generation
  - `Youth/` — Tab-based: resource swipe, career path, chat hub, counselor list
  - `Counselor/` — Tab-based: appointments, case tracking, profile
- **Components/** — Reusable UI: `ResourceCardView`, `AvatarView`, `CloudBackground`, `CommonComponents`
- **Theme/** — `CloudTheme` (colors, gradients) and `ColorHex` helper

Screen flow is driven by `AppState.screen` (`AppScreen` enum) and rendered in `RootView.swift`.

### Mock Backend (`mock_backend/app/`)

- **main.py** — All FastAPI routes in a single file. Reads/writes `data.py` in-memory stores directly.
- **schemas.py** — Pydantic models mirroring the iOS `CloudModels.swift`.
- **data.py** — In-memory data store (resets on restart).

### Dual Data Layers

The iOS app currently has **two data paths**:
1. `AppState` + `MockData` — fully local mock data for offline development
2. `APIService` + `APIModels` — real HTTP client targeting the production backend

The mock backend is a separate third layer for API-level testing. Schemas in `mock_backend/app/schemas.py` should stay aligned with `CloudModels.swift`.

## Language

UI strings and comments are in Traditional Chinese (繁體中文). Code identifiers are in English.
