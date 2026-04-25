"""青年��人檔案：GET/PATCH /youth/me, POST /youth/me/avatar"""
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import User, CitizenProfile

router = APIRouter(prefix="/youth", tags=["youth"])


# ---------- Schemas ----------

class YouthProfileResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    age: int | None
    school: str | None
    major: str | None
    location: str | None
    bio: str | None
    interests: list | None
    skills: list | None
    education_level: str | None
    department: str | None
    goal: str | None
    achievement: str | None
    setback: str | None
    holland_primary: str | None
    holland_secondary: str | None
    counselor_list: list | None
    career_path: list | None
    avatar_url: str | None
    created_at: datetime
    updated_at: datetime


class YouthProfileUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    school: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    interests: Optional[list] = None
    skills: Optional[list] = None
    education_level: Optional[str] = None
    department: Optional[str] = None
    goal: Optional[str] = None
    achievement: Optional[str] = None
    setback: Optional[str] = None
    holland_primary: Optional[str] = None
    holland_secondary: Optional[str] = None
    counselor_list: Optional[list] = None


class YouthProfileCreate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    school: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    interests: Optional[list] = None
    skills: Optional[list] = None
    education_level: Optional[str] = None
    department: Optional[str] = None
    goal: Optional[str] = None
    achievement: Optional[str] = None
    setback: Optional[str] = None
    holland_primary: Optional[str] = None
    holland_secondary: Optional[str] = None
    counselor_list: Optional[list] = None


# ---------- Helpers ----------

async def _get_profile(user_id: uuid.UUID, db: AsyncSession) -> tuple:
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(404, "User not found")
    result = await db.execute(
        select(CitizenProfile).where(CitizenProfile.user_id == user_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        profile = CitizenProfile(user_id=user_id)
        db.add(profile)
        await db.flush()
    return user, profile


def _to_response(user: User, profile: CitizenProfile) -> dict:
    return {
        "id": profile.id,
        "user_id": user.id,
        "name": user.name,
        "age": profile.age,
        "school": profile.school,
        "major": user.major,
        "location": profile.location,
        "bio": profile.bio,
        "interests": profile.interests,
        "skills": profile.skills,
        "education_level": profile.education_level,
        "department": profile.department,
        "goal": profile.goal,
        "achievement": profile.achievement,
        "setback": profile.setback,
        "holland_primary": profile.holland_primary,
        "holland_secondary": profile.holland_secondary,
        "counselor_list": profile.counselor_list,
        "career_path": profile.career_path,
        "avatar_url": user.avatar_url,
        "created_at": profile.created_at,
        "updated_at": profile.updated_at,
    }


# ---------- Endpoints ----------

@router.post("/me", response_model=YouthProfileResponse, status_code=201, summary="建立青年個人檔案")
async def create_youth_me(
    user_id: uuid.UUID,
    body: YouthProfileCreate,
    db: AsyncSession = Depends(get_db),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(404, "User not found")

    result = await db.execute(
        select(CitizenProfile).where(CitizenProfile.user_id == user_id)
    )
    profile = result.scalar_one_or_none()
    if profile:
        raise HTTPException(409, "Youth profile already exists")

    profile = CitizenProfile(user_id=user_id)
    updates = body.model_dump(exclude_unset=True)

    if "name" in updates:
        user.name = updates.pop("name")

    for field, value in updates.items():
        setattr(profile, field, value)

    user.role = "citizen"
    db.add(profile)
    await db.flush()
    return _to_response(user, profile)

@router.get("/me", response_model=YouthProfileResponse, summary="取得青年個人檔案")
async def get_youth_me(user_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """以 query param user_id 取得青年檔��。未來改為從 JWT token 取得。"""
    user, profile = await _get_profile(user_id, db)
    return _to_response(user, profile)


@router.patch("/me", response_model=YouthProfileResponse, summary="更新青年個人檔案")
async def update_youth_me(
    user_id: uuid.UUID,
    body: YouthProfileUpdate,
    db: AsyncSession = Depends(get_db),
):
    user, profile = await _get_profile(user_id, db)
    updates = body.model_dump(exclude_unset=True)

    # name 存在 user 表
    if "name" in updates:
        user.name = updates.pop("name")

    for field, value in updates.items():
        setattr(profile, field, value)

    await db.flush()
    return _to_response(user, profile)


@router.post("/me/avatar", response_model=YouthProfileResponse, summary="上傳頭像")
async def upload_avatar(
    user_id: uuid.UUID,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(400, "只接受 JPEG / PNG / WebP")
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(400, "檔案大小不得超過 5MB")

    user, profile = await _get_profile(user_id, db)
    # 簡易方案：存 base64 data URI；正式環境應改用 object storage
    import base64
    data_uri = f"data:{file.content_type};base64,{base64.b64encode(content).decode()}"
    user.avatar_url = data_uri
    await db.flush()
    return _to_response(user, profile)
