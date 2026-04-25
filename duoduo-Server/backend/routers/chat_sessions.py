"""聊天系統：AI 對話 + 諮商師對話（簡易版，對齊 mock_backend）"""
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import CitizenProfile, ChatSession, ChatMessage as ChatMessageModel
from ..services import llm, rag

router = APIRouter(prefix="/chat", tags=["chat-sessions"])


# ---------- Schemas ----------

class ChatMessageResponse(BaseModel):
    id: uuid.UUID
    sender_type: str
    message: str
    created_at: str


class ChatRequest(BaseModel):
    content: str


# ---------- Helpers ----------

async def _get_citizen(user_id: uuid.UUID, db: AsyncSession) -> CitizenProfile:
    result = await db.execute(
        select(CitizenProfile).where(CitizenProfile.user_id == user_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(404, "Citizen profile not found")
    return profile


async def _get_or_create_session(citizen_id: uuid.UUID, mode: str, db: AsyncSession) -> ChatSession:
    result = await db.execute(
        select(ChatSession).where(
            ChatSession.citizen_id == citizen_id,
            ChatSession.mode == mode,
        ).order_by(ChatSession.created_at.desc())
    )
    session = result.scalar_one_or_none()
    if not session:
        session = ChatSession(citizen_id=citizen_id, mode=mode)
        db.add(session)
        await db.flush()
    return session


def _msg_to_response(msg: ChatMessageModel) -> dict:
    return {
        "id": msg.id,
        "sender_type": msg.sender_type,
        "message": msg.message,
        "created_at": msg.created_at.isoformat() if msg.created_at else "",
    }


# ---------- AI Chat ----------

@router.get("/ai", response_model=list[ChatMessageResponse], summary="取得 AI 對話歷史")
async def get_ai_chat(
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    session = await _get_or_create_session(citizen.id, "ai", db)
    result = await db.execute(
        select(ChatMessageModel)
        .where(ChatMessageModel.session_id == session.id)
        .order_by(ChatMessageModel.created_at)
    )
    return [_msg_to_response(m) for m in result.scalars().all()]


@router.post("/ai", response_model=ChatMessageResponse, summary="發送 AI 對話訊息")
async def post_ai_chat(
    body: ChatRequest,
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    session = await _get_or_create_session(citizen.id, "ai", db)

    # 儲存使用者訊息
    user_msg = ChatMessageModel(
        session_id=session.id, sender_type="citizen", message=body.content
    )
    db.add(user_msg)
    await db.flush()

    # RAG + LLM 回覆
    try:
        resources = await rag.query_resources(body.content)
        rag_context = "\n".join(
            f"- {r['content']}（來源：{r['source']}，連結：{r['url']}）" for r in resources
        )

        # 取得最近歷史
        history_result = await db.execute(
            select(ChatMessageModel)
            .where(ChatMessageModel.session_id == session.id)
            .order_by(ChatMessageModel.created_at.desc())
            .limit(20)
        )
        history_msgs = list(reversed(history_result.scalars().all()))
        history_dicts = [
            {"role": "user" if m.sender_type == "citizen" else "model", "content": m.message}
            for m in history_msgs[:-1]  # exclude the message we just added
        ]

        reply_text = await llm.chat(history_dicts, body.content, rag_context)
    except Exception:
        reply_text = f"收到你的訊息：「{body.content}」。目前 AI 服務暫時無法使用，請稍後再試。"

    ai_msg = ChatMessageModel(
        session_id=session.id, sender_type="ai", message=reply_text
    )
    db.add(ai_msg)
    await db.flush()
    return _msg_to_response(ai_msg)


# ---------- Counselor Chat ----------

@router.get("/counselor", response_model=list[ChatMessageResponse], summary="取得諮商師對話歷史")
async def get_counselor_chat(
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    session = await _get_or_create_session(citizen.id, "counselor", db)
    result = await db.execute(
        select(ChatMessageModel)
        .where(ChatMessageModel.session_id == session.id)
        .order_by(ChatMessageModel.created_at)
    )
    return [_msg_to_response(m) for m in result.scalars().all()]


@router.post("/counselor", response_model=ChatMessageResponse, summary="發送諮商師對話訊息")
async def post_counselor_chat(
    body: ChatRequest,
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    session = await _get_or_create_session(citizen.id, "counselor", db)

    user_msg = ChatMessageModel(
        session_id=session.id, sender_type="citizen", message=body.content
    )
    db.add(user_msg)
    await db.flush()

    # 簡易自動回覆（正式環境由諮商師端回覆）
    reply = ChatMessageModel(
        session_id=session.id,
        sender_type="counselor",
        message="收到～我等等回覆你詳細的，先看看相關諮詢服務 ☁️",
    )
    db.add(reply)
    await db.flush()
    return _msg_to_response(reply)
