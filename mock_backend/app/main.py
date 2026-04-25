"""FastAPI 入口。所有 endpoint 直接讀寫 app/data.py 中的 in-memory store。"""
from __future__ import annotations
from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import UUID
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import data
from .schemas import (
    YouthProfile, YouthProfileUpdate,
    ResourceCard, ResourceCategory, Counselor, Appointment,
    CounselingCase, CaseTag, ChatMessage, ChatSender,
    SwipeRequest, SwipeDirection, ChatRequest, AddTagRequest, RecommendRequest,
    ApplicationStatus, ApplicationStatusResponse,
    CounselorMatchStatus, CounselorMatchResponse,
)

app = FastAPI(
    title="朵朵 Cloud Hub Mock API",
    description="提供 iOS App 開發階段使用的 mock backend。",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path(__file__).parent.parent / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")


# ---------- Health ----------
@app.get("/health")
def health() -> dict:
    return {"status": "ok", "time": datetime.utcnow().isoformat()}


# ---------- Youth ----------
@app.get("/youth/me", response_model=YouthProfile)
def get_youth_me() -> YouthProfile:
    return data.youth_profile


@app.patch("/youth/me", response_model=YouthProfile)
def update_youth_me(body: YouthProfileUpdate) -> YouthProfile:
    update = body.model_dump(exclude_unset=True)
    for k, v in update.items():
        setattr(data.youth_profile, k, v)
    return data.youth_profile


@app.post("/youth/me/avatar", response_model=YouthProfile)
async def upload_avatar(file: UploadFile = File(...)) -> YouthProfile:
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(400, "只接受 JPEG / PNG / WebP")
    ext = file.filename.rsplit(".", 1)[-1] if file.filename else "jpg"
    filename = f"avatar_{data.youth_profile.id}.{ext}"
    path = UPLOAD_DIR / filename
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(400, "檔案大小不得超過 5MB")
    path.write_bytes(content)
    data.youth_profile.avatarImage = filename
    return data.youth_profile


# ---------- Resources ----------
@app.get("/resources", response_model=list[ResourceCard])
def list_resources(category: Optional[ResourceCategory] = None) -> list[ResourceCard]:
    if category is None:
        return data.resources
    return [r for r in data.resources if r.category == category]


@app.get("/resources/liked", response_model=list[ResourceCard])
def liked_resources() -> list[ResourceCard]:
    return [r for r in data.resources if r.id in data.liked_resource_ids]


@app.post("/resources/{resource_id}/swipe")
def swipe_resource(resource_id: UUID, body: SwipeRequest) -> dict:
    if not any(r.id == resource_id for r in data.resources):
        raise HTTPException(404, "resource not found")
    if body.direction == SwipeDirection.right:
        data.liked_resource_ids.add(resource_id)
    else:
        data.passed_resource_ids.add(resource_id)
    return {"ok": True, "direction": body.direction}


# ---------- Counselors ----------
@app.get("/counselors", response_model=list[Counselor])
def list_counselors() -> list[Counselor]:
    return data.counselors


# ---------- Appointments ----------
@app.get("/appointments", response_model=list[Appointment])
def list_appointments() -> list[Appointment]:
    return data.appointments


# ---------- Cases ----------
@app.get("/cases", response_model=list[CounselingCase])
def list_cases() -> list[CounselingCase]:
    return data.cases


@app.get("/case-tags", response_model=list[CaseTag])
def list_case_tags() -> list[CaseTag]:
    return data.case_tags


@app.post("/cases/{case_id}/tags", response_model=CounselingCase)
def add_tag(case_id: UUID, body: AddTagRequest) -> CounselingCase:
    case = next((c for c in data.cases if c.id == case_id), None)
    if not case:
        raise HTTPException(404, "case not found")
    tag = next((t for t in data.case_tags if t.id == body.tagId), None)
    if not tag:
        raise HTTPException(404, "tag not found")
    if tag not in case.tags:
        case.tags.append(tag)
    return case


@app.post("/cases/{case_id}/recommend", response_model=CounselingCase)
def recommend_resource(case_id: UUID, body: RecommendRequest) -> CounselingCase:
    case = next((c for c in data.cases if c.id == case_id), None)
    if not case:
        raise HTTPException(404, "case not found")
    if not any(r.id == body.resourceId for r in data.resources):
        raise HTTPException(404, "resource not found")
    if body.resourceId not in case.recommendedResourceIds:
        case.recommendedResourceIds.append(body.resourceId)
    # 同步附帶到諮商師訊息（模擬發送卡片）
    data.counselor_messages.append(
        ChatMessage(
            sender=ChatSender.counselor,
            content="幫你推薦這份資源，看看適不適合 ☁️",
            attachedResourceId=body.resourceId,
        )
    )
    return case


# ---------- Chat ----------
def _fake_ai_reply(text: str) -> str:
    """簡易 LLM 占位邏輯，之後替換為真正的 RAG / LLM。"""
    t = text.lower()
    if "補助" in text or "貸款" in text:
        return ("我幫你找了幾個方向：\n"
                "1. 青年創業及啟動金貸款（最高 400 萬）\n"
                "2. 青年初次尋職津貼（最高 3 萬）\n"
                "你想先了解哪一個？")
    if "履歷" in text or "面試" in text:
        return ("我們可以從三件事著手：\n"
                "• 量化你的成果（用數字說話）\n"
                "• 找一份你想投的 JD 對照需要的關鍵字\n"
                "• 預約一次 TYS 履歷健診 ☁️")
    return f"嗯嗯，我聽到你說：「{text}」。\n可以再多告訴我一點嗎？我會幫你整理出可以使用的青年資源 💖"


@app.get("/chat/ai", response_model=list[ChatMessage])
def get_ai_chat() -> list[ChatMessage]:
    return data.ai_messages


@app.post("/chat/ai", response_model=ChatMessage)
def post_ai_chat(body: ChatRequest) -> ChatMessage:
    data.ai_messages.append(ChatMessage(sender=ChatSender.user, content=body.content))
    reply = ChatMessage(sender=ChatSender.ai, content=_fake_ai_reply(body.content))
    data.ai_messages.append(reply)
    return reply


@app.get("/chat/counselor", response_model=list[ChatMessage])
def get_counselor_chat() -> list[ChatMessage]:
    return data.counselor_messages


@app.post("/chat/counselor", response_model=ChatMessage)
def post_counselor_chat(body: ChatRequest) -> ChatMessage:
    data.counselor_messages.append(ChatMessage(sender=ChatSender.user, content=body.content))
    reply = ChatMessage(
        sender=ChatSender.counselor,
        content="收到～我等等回覆你詳細的，先看看「臺北青年職涯發展中心」的諮詢服務 ☁️",
    )
    data.counselor_messages.append(reply)
    return reply


# ---------- Resource Application ----------
@app.post("/resources/{resource_id}/apply", response_model=ApplicationStatusResponse)
def apply_resource(resource_id: UUID) -> ApplicationStatusResponse:
    if not any(r.id == resource_id for r in data.resources):
        raise HTTPException(404, "resource not found")
    rid = str(resource_id)
    current = data.application_statuses.get(rid)
    if current == ApplicationStatus.accepted:
        raise HTTPException(400, "已報名成功，無法重複申請")
    data.application_statuses[rid] = ApplicationStatus.applying
    return ApplicationStatusResponse(resourceId=resource_id, status=ApplicationStatus.applying)


@app.post("/resources/{resource_id}/confirm", response_model=ApplicationStatusResponse)
def confirm_resource(resource_id: UUID) -> ApplicationStatusResponse:
    """Mock：模擬報名成功（實際上由管理端觸發）。"""
    rid = str(resource_id)
    if rid not in data.application_statuses:
        raise HTTPException(404, "尚未申請此資源")
    data.application_statuses[rid] = ApplicationStatus.accepted
    return ApplicationStatusResponse(resourceId=resource_id, status=ApplicationStatus.accepted)


@app.get("/resources/applications", response_model=list[ApplicationStatusResponse])
def list_applications() -> list[ApplicationStatusResponse]:
    return [
        ApplicationStatusResponse(resourceId=UUID(k), status=v)
        for k, v in data.application_statuses.items()
    ]


# ---------- Counselor Match ----------
@app.post("/counselors/{counselor_id}/apply", response_model=CounselorMatchResponse)
def apply_counselor(counselor_id: UUID) -> CounselorMatchResponse:
    if not any(c.id == counselor_id for c in data.counselors):
        raise HTTPException(404, "counselor not found")
    if data.selected_counselor_id and data.selected_counselor_id != str(counselor_id):
        raise HTTPException(400, "已有配對的諮商師，請先取消")
    data.selected_counselor_id = str(counselor_id)
    data.counselor_match[str(counselor_id)] = CounselorMatchStatus.applied
    return CounselorMatchResponse(counselorId=counselor_id, status=CounselorMatchStatus.applied)


@app.post("/counselors/{counselor_id}/schedule", response_model=CounselorMatchResponse)
def schedule_counselor(counselor_id: UUID) -> CounselorMatchResponse:
    """Mock：模擬諮商師確認排程。"""
    cid = str(counselor_id)
    if cid not in data.counselor_match:
        raise HTTPException(404, "尚未申請此諮商師")
    data.counselor_match[cid] = CounselorMatchStatus.scheduled
    return CounselorMatchResponse(counselorId=counselor_id, status=CounselorMatchStatus.scheduled)


@app.delete("/counselors/match")
def cancel_counselor_match() -> dict:
    data.selected_counselor_id = None
    data.counselor_match.clear()
    return {"ok": True}


@app.get("/counselors/match", response_model=Optional[CounselorMatchResponse])
def get_counselor_match() -> Optional[CounselorMatchResponse]:
    if not data.selected_counselor_id:
        return None
    cid = data.selected_counselor_id
    status = data.counselor_match.get(cid, CounselorMatchStatus.none)
    return CounselorMatchResponse(counselorId=UUID(cid), status=status)
