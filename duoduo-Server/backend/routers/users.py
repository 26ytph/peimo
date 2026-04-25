import uuid
from datetime import datetime
from hashlib import sha256

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import User

router = APIRouter(prefix="/users", tags=["users"])


class UserCreate(BaseModel):
    account: str = Field(..., description="登入帳號（需唯一）", examples=["wiwi"])
    password: str = Field(..., description="明文密碼（API 內會轉成雜湊儲存）", examples=["wiwi"])
    role: str = Field(..., description="角色：citizen / counselor / admin", examples=["citizen"])
    name: str = Field(..., description="顯示名稱", examples=["威威"])
    email: str | None = Field(None, description="電子郵件（可選，需唯一）", examples=["wiwi@example.com"])
    avatar_url: str | None = Field(None, description="頭像網址（可選）", examples=["https://example.com/avatar.png"])


class UserUpdate(BaseModel):
    password: str | None = Field(None, description="新密碼")
    role: str | None = Field(None, description="新角色")
    name: str | None = Field(None, description="新名稱")
    email: str | None = Field(None, description="新電子郵件")
    avatar_url: str | None = Field(None, description="新頭像網址")


class UserResponse(BaseModel):
    id: uuid.UUID
    account: str
    role: str
    name: str
    email: str | None
    avatar_url: str | None
    created_at: datetime
    updated_at: datetime


@router.get(
    "",
    response_model=list[UserResponse],
    summary="列出所有使用者",
    description="取得 users 表中的使用者清單，依建立時間新到舊排序。\n\n使用方式：直接呼叫即可，無需參數。",
    response_description="使用者清單。",
)
async def list_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).order_by(User.created_at.desc()))
    return result.scalars().all()


@router.get(
    "/{user_id}",
    response_model=UserResponse,
    summary="查詢單一使用者",
    description="用 user_id 查詢單筆使用者資料。\n\n使用方式：在路徑填入 UUID。",
    response_description="使用者資料。",
)
async def get_user(user_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post(
    "",
    response_model=UserResponse,
    status_code=201,
    summary="建立使用者",
    description="新增一筆使用者資料。\n\n使用方式：送出 account、password、role、name；password 會自動轉為雜湊。",
    response_description="新建立的使用者資料。",
)
async def create_user(req: UserCreate, db: AsyncSession = Depends(get_db)):
    user = User(
        account=req.account,
        password_hash=sha256(req.password.encode("utf-8")).hexdigest(),
        role=req.role,
        name=req.name,
        email=req.email,
        avatar_url=req.avatar_url,
    )
    db.add(user)
    try:
        await db.flush()
    except IntegrityError:
        raise HTTPException(status_code=409, detail="Account or email already exists")
    return user


@router.patch(
    "/{user_id}",
    response_model=UserResponse,
    summary="更新使用者",
    description="部分更新使用者欄位。\n\n使用方式：路徑放 user_id，Body 只帶要修改的欄位。",
    response_description="更新後的使用者資料。",
)
async def update_user(user_id: uuid.UUID, req: UserUpdate, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if req.password is not None:
        user.password_hash = sha256(req.password.encode("utf-8")).hexdigest()
    if req.role is not None:
        user.role = req.role
    if req.name is not None:
        user.name = req.name
    if req.email is not None:
        user.email = req.email
    if req.avatar_url is not None:
        user.avatar_url = req.avatar_url

    try:
        await db.flush()
    except IntegrityError:
        raise HTTPException(status_code=409, detail="Account or email already exists")
    return user


@router.delete(
    "/{user_id}",
    status_code=204,
    summary="刪除使用者",
    description="刪除指定使用者。\n\n使用方式：在路徑填入 user_id，成功後不回傳內容。",
    response_description="刪除成功（無內容）。",
)
async def delete_user(user_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await db.delete(user)
