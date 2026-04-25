"""個案管理：標籤、推薦資源"""
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import CaseRecord, CaseTag, CaseTagLink, Recommendation, Resource

router = APIRouter(tags=["case-management"])


# ---------- Schemas ----------

class CaseTagResponse(BaseModel):
    id: uuid.UUID
    name: str


class CaseTagRequest(BaseModel):
    tag_id: uuid.UUID


class RecommendRequest(BaseModel):
    resource_id: uuid.UUID


# ---------- Endpoints ----------

@router.get("/case-tags", response_model=list[CaseTagResponse], summary="列出所有個案標籤")
async def list_case_tags(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CaseTag))
    return result.scalars().all()


@router.post("/cases/{case_id}/tags", summary="為個案加上標籤")
async def add_case_tag(
    case_id: uuid.UUID,
    body: CaseTagRequest,
    db: AsyncSession = Depends(get_db),
):
    case = await db.get(CaseRecord, case_id)
    if not case:
        raise HTTPException(404, "Case not found")
    tag = await db.get(CaseTag, body.tag_id)
    if not tag:
        raise HTTPException(404, "Tag not found")

    # 避免重複
    existing = await db.execute(
        select(CaseTagLink).where(
            CaseTagLink.case_record_id == case_id,
            CaseTagLink.tag_id == body.tag_id,
        )
    )
    if existing.scalar_one_or_none():
        return {"ok": True, "message": "Tag already exists"}

    link = CaseTagLink(case_record_id=case_id, tag_id=body.tag_id)
    db.add(link)
    await db.flush()
    return {"ok": True}


@router.post("/cases/{case_id}/recommend", summary="為個案推薦資源")
async def recommend_resource(
    case_id: uuid.UUID,
    body: RecommendRequest,
    user_id: uuid.UUID = Query(..., description="操作者（諮商師）的 user_id"),
    db: AsyncSession = Depends(get_db),
):
    case = await db.get(CaseRecord, case_id)
    if not case:
        raise HTTPException(404, "Case not found")
    resource = await db.get(Resource, body.resource_id)
    if not resource:
        raise HTTPException(404, "Resource not found")

    rec = Recommendation(
        citizen_id=case.citizen_id,
        resource_id=body.resource_id,
        counselor_id=case.counselor_id,
        recommender_type="counselor",
    )
    db.add(rec)
    await db.flush()
    return {"ok": True}
