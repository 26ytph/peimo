# AI 諮商路由：對話 + RAG 資源注入 + 真人轉介判斷
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models.user import Consultation, User
from ..services import llm, rag

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatMessage(BaseModel):
    role: str  # "user" or "model"
    content: str


class ChatRequest(BaseModel):
    user_id: uuid.UUID
    message: str
    history: list[ChatMessage] = []


class ChatResponse(BaseModel):
    reply: str
    needs_human_handoff: bool


@router.post("/message", response_model=ChatResponse)
async def send_message(req: ChatRequest, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, req.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="使用者不存在")

    # RAG 查詢語意相關資源
    resources = await rag.query_resources(req.message)
    rag_context = "\n".join(
        f"- {r['content']}（來源：{r['source']}，連結：{r['url']}）" for r in resources
    )

    # LLM 對話
    history_dicts = [{"role": m.role, "content": m.content} for m in req.history]
    reply = await llm.chat(history_dicts, req.message, rag_context)

    # 組合完整對話紀錄供複雜度評估
    full_transcript = "\n".join(
        f"{m.role}: {m.content}" for m in req.history
    ) + f"\nuser: {req.message}\nassistant: {reply}"

    needs_handoff = await llm.assess_complexity(full_transcript)

    # 存入諮詢紀錄
    consultation = Consultation(
        user_id=req.user_id,
        type="human" if needs_handoff else "ai",
        transcript=full_transcript,
    )
    db.add(consultation)
    await db.flush()

    return ChatResponse(reply=reply, needs_human_handoff=needs_handoff)
