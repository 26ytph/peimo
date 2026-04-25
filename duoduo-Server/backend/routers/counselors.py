"""諮商師瀏覽、配對、預約"""
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import User, CounselorProfile, CitizenProfile, CounselorAssignment, Appointment

router = APIRouter(tags=["counselors"])


# ---------- Schemas ----------

class CounselorResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    title: str | None
    specialty: list | None
    introduction: str | None
    status: str
    years_experience: int | None
    avatar_url: str | None


class CounselorMatchResponse(BaseModel):
    counselor_id: uuid.UUID
    status: str  # 未申請 / 已申請 / 已安排 / 諮商中


class AppointmentResponse(BaseModel):
    id: uuid.UUID
    citizen_id: uuid.UUID
    counselor_id: uuid.UUID
    status: str
    scheduled_at: datetime
    note: str | None
    created_at: datetime


# ---------- Helpers ----------

async def _get_citizen(user_id: uuid.UUID, db: AsyncSession) -> CitizenProfile:
    result = await db.execute(
        select(CitizenProfile).where(CitizenProfile.user_id == user_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(404, "Citizen profile not found")
    return profile


async def _get_counselor_profile(counselor_id: uuid.UUID, db: AsyncSession) -> CounselorProfile:
    """counselor_id here is the CounselorProfile.id (not user_id)."""
    profile = await db.get(CounselorProfile, counselor_id)
    if not profile:
        raise HTTPException(404, "Counselor not found")
    return profile


# ---------- Endpoints ----------

@router.get("/counselors", response_model=list[CounselorResponse], summary="列出所有諮商師")
async def list_counselors(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(CounselorProfile, User)
        .join(User, CounselorProfile.user_id == User.id)
    )
    rows = result.all()
    return [
        CounselorResponse(
            id=cp.id, user_id=cp.user_id, name=u.name,
            title=cp.title, specialty=cp.specialty,
            introduction=cp.introduction, status=cp.status,
            years_experience=cp.years_experience, avatar_url=u.avatar_url,
        )
        for cp, u in rows
    ]


@router.post("/counselors/{counselor_id}/apply", response_model=CounselorMatchResponse, summary="申請配對諮商師")
async def apply_counselor(
    counselor_id: uuid.UUID,
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    await _get_counselor_profile(counselor_id, db)

    # 檢查是否已有 active 的配對
    existing = await db.execute(
        select(CounselorAssignment).where(
            CounselorAssignment.citizen_id == citizen.id,
            CounselorAssignment.status == "active",
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, "已有配對的諮商師，請先取消")

    assignment = CounselorAssignment(
        citizen_id=citizen.id, counselor_id=counselor_id, status="active"
    )
    db.add(assignment)
    await db.flush()
    return CounselorMatchResponse(counselor_id=counselor_id, status="已申請")


@router.post("/counselors/{counselor_id}/schedule", response_model=CounselorMatchResponse, summary="諮商師確認排程")
async def schedule_counselor(
    counselor_id: uuid.UUID,
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    result = await db.execute(
        select(CounselorAssignment).where(
            CounselorAssignment.citizen_id == citizen.id,
            CounselorAssignment.counselor_id == counselor_id,
            CounselorAssignment.status == "active",
        )
    )
    assignment = result.scalar_one_or_none()
    if not assignment:
        raise HTTPException(404, "尚未申請此諮商師")
    assignment.status = "scheduled"
    await db.flush()
    return CounselorMatchResponse(counselor_id=counselor_id, status="已安排")


@router.get("/counselors/match", response_model=Optional[CounselorMatchResponse], summary="查詢目前配對狀態")
async def get_counselor_match(
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    result = await db.execute(
        select(CounselorAssignment).where(
            CounselorAssignment.citizen_id == citizen.id,
            CounselorAssignment.status.in_(["active", "scheduled"]),
        )
    )
    assignment = result.scalar_one_or_none()
    if not assignment:
        return None
    status_map = {"active": "已申請", "scheduled": "已安排"}
    return CounselorMatchResponse(
        counselor_id=assignment.counselor_id,
        status=status_map.get(assignment.status, assignment.status),
    )


@router.delete("/counselors/match", summary="取消諮商師配對")
async def cancel_counselor_match(
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    result = await db.execute(
        select(CounselorAssignment).where(
            CounselorAssignment.citizen_id == citizen.id,
            CounselorAssignment.status.in_(["active", "scheduled"]),
        )
    )
    assignment = result.scalar_one_or_none()
    if assignment:
        assignment.status = "ended"
        await db.flush()
    return {"ok": True}


@router.get("/appointments", response_model=list[AppointmentResponse], summary="列出預約")
async def list_appointments(
    user_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    citizen = await _get_citizen(user_id, db)
    result = await db.execute(
        select(Appointment)
        .where(Appointment.citizen_id == citizen.id)
        .order_by(Appointment.scheduled_at.desc())
    )
    return result.scalars().all()
