"""職涯路徑生成：根據夢想與背景，由 LLM 規劃多階段職涯路徑"""
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import User, CitizenProfile
from ..services import llm, rag

router = APIRouter(prefix="/path", tags=["path"])


# ---------- Schemas ----------

class PathRequest(BaseModel):
    user_id: uuid.UUID
    dream: str
    background: dict = {}


class PathStage(BaseModel):
    title: str
    content: str
    resources: list[str]


class PathResponse(BaseModel):
    user_id: uuid.UUID
    dream: str
    stages: list[PathStage]


# ---------- Endpoints ----------

@router.post("/generate", response_model=PathResponse, summary="生成職涯路徑")
async def generate_path(req: PathRequest, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, req.user_id)
    if not user:
        raise HTTPException(404, "使用者不存在")

    # 取得 citizen profile
    result = await db.execute(
        select(CitizenProfile).where(CitizenProfile.user_id == req.user_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        profile = CitizenProfile(user_id=req.user_id)
        db.add(profile)
        await db.flush()

    # RAG 查詢相關資源
    resources = await rag.query_resources(req.dream)
    rag_context = "\n".join(
        f"- {r['title']}：{r['content']}（來源：{r['source']}，連結：{r['url']}）"
        for r in resources
    )

    # LLM 生成多階段路徑
    stages = await llm.generate_path(req.dream, req.background, rag_context)

    # 存入 citizen profile
    profile.career_path = stages
    user.dream = req.dream
    await db.flush()

    return PathResponse(user_id=req.user_id, dream=req.dream, stages=stages)
