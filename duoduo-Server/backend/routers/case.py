# 社交案例路由：案例的新增與查詢
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models.user import Case, User

router = APIRouter(prefix="/cases", tags=["cases"])


class CaseCreate(BaseModel):
    user_id: uuid.UUID
    dream: str
    summary: str
    resources_used: list = []


class CaseResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    dream: str
    summary: str
    resources_used: list
    created_at: datetime


@router.get("", response_model=list[CaseResponse])
async def list_cases(
    dream: str | None = Query(None, description="依夢想關鍵字篩選"),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Case)
    if dream:
        stmt = stmt.where(Case.dream.ilike(f"%{dream}%"))
    stmt = stmt.order_by(Case.created_at.desc())

    result = await db.execute(stmt)
    cases = result.scalars().all()
    return cases


@router.post("", response_model=CaseResponse, status_code=201)
async def create_case(req: CaseCreate, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, req.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="使用者不存在")

    case = Case(
        user_id=req.user_id,
        dream=req.dream,
        summary=req.summary,
        resources_used=req.resources_used,
    )
    db.add(case)
    await db.flush()

    return case
