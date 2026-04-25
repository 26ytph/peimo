"""資源卡片互動：分類瀏覽、收藏、滑動、申請"""
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import Resource, ResourceSwipe, CitizenProfile

router = APIRouter(tags=["resource-interactions"])


# ---------- Schemas ----------

class ResourceCardResponse(BaseModel):
    id: uuid.UUID
    title: str
    content: str
    tags: list | None
    source: str | None
    url: str | None
    created_at: datetime
    updated_at: datetime


class SwipeRequest(BaseModel):
    direction: str  # "left" (pass) / "right" (like)


class ApplicationStatusResponse(BaseModel):
    resource_id: uuid.UUID
    status: str  # 未申請 / 申請中 / 報名成功


# ---------- Helpers ----------

async def _get_citizen_profile(user_id: uuid.UUID, db: AsyncSession) -> CitizenProfile:
    result = await db.execute(
        select(CitizenProfile).where(CitizenProfile.user_id == user_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(404, "Citizen profile not found")
    return profile


# ---------- Endpoints ----------

@router.get("/resources/browse", response_model=list[ResourceCardResponse], summary="瀏覽資源卡片")
async def browse_resources(
    tag: Optional[str] = Query(None, description="依標籤篩選"),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Resource)
    if tag:
        stmt = stmt.where(Resource.tags.contains([tag]))
    stmt = stmt.order_by(Resource.created_at.desc())
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/resources/liked", response_model=list[ResourceCardResponse], summary="已收藏的資源")
async def liked_resources(
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_citizen_profile(user_id, db)
    stmt = (
        select(Resource)
        .join(ResourceSwipe, ResourceSwipe.resource_id == Resource.id)
        .where(ResourceSwipe.citizen_id == profile.id, ResourceSwipe.action == "like")
        .order_by(ResourceSwipe.created_at.desc())
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.post("/resources/{resource_id}/swipe", summary="滑動資源卡片")
async def swipe_resource(
    resource_id: uuid.UUID,
    body: SwipeRequest,
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    resource = await db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(404, "Resource not found")
    profile = await _get_citizen_profile(user_id, db)

    action = "like" if body.direction == "right" else "dislike"
    swipe = ResourceSwipe(citizen_id=profile.id, resource_id=resource_id, action=action)
    db.add(swipe)
    await db.flush()
    return {"ok": True, "direction": body.direction}


@router.post("/resources/{resource_id}/apply", response_model=ApplicationStatusResponse, summary="申請資源")
async def apply_resource(
    resource_id: uuid.UUID,
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    resource = await db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(404, "Resource not found")
    profile = await _get_citizen_profile(user_id, db)

    # 檢查是否已有 save 類型的 swipe（當作申請紀錄）
    existing = await db.execute(
        select(ResourceSwipe).where(
            ResourceSwipe.citizen_id == profile.id,
            ResourceSwipe.resource_id == resource_id,
            ResourceSwipe.action == "save",
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, "已申請此資源")

    swipe = ResourceSwipe(citizen_id=profile.id, resource_id=resource_id, action="save")
    db.add(swipe)
    await db.flush()
    return ApplicationStatusResponse(resource_id=resource_id, status="申請中")


@router.post("/resources/{resource_id}/confirm", response_model=ApplicationStatusResponse, summary="確認報名成功")
async def confirm_resource(
    resource_id: uuid.UUID,
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_citizen_profile(user_id, db)
    result = await db.execute(
        select(ResourceSwipe).where(
            ResourceSwipe.citizen_id == profile.id,
            ResourceSwipe.resource_id == resource_id,
            ResourceSwipe.action == "save",
        )
    )
    swipe = result.scalar_one_or_none()
    if not swipe:
        raise HTTPException(404, "尚未申請此資源")
    # 用 action 欄位區分狀態：save=申請中，confirmed=報名成功
    swipe.action = "confirmed"
    await db.flush()
    return ApplicationStatusResponse(resource_id=resource_id, status="報名成功")


@router.get("/resources/applications", response_model=list[ApplicationStatusResponse], summary="查詢所有申請狀態")
async def list_applications(
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_citizen_profile(user_id, db)
    result = await db.execute(
        select(ResourceSwipe).where(
            ResourceSwipe.citizen_id == profile.id,
            ResourceSwipe.action.in_(["save", "confirmed"]),
        )
    )
    swipes = result.scalars().all()
    statuses = []
    for s in swipes:
        status = "報名成功" if s.action == "confirmed" else "申請中"
        statuses.append(ApplicationStatusResponse(resource_id=s.resource_id, status=status))
    return statuses
