# 登入路由：檢查帳號與密碼是否正確
from hashlib import sha256

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models.user import User

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginRequest(BaseModel):
    account: str
    password: str


class LoginResponse(BaseModel):
    success: bool
    user_id: str | None = None
    name: str | None = None


@router.post("/login", response_model=LoginResponse)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.account == req.account).limit(1))
    user = result.scalar_one_or_none()

    if user is None or user.password_hash is None:
        raise HTTPException(status_code=401, detail="帳號或密碼錯誤")

    password_hash = sha256(req.password.encode("utf-8")).hexdigest()
    if password_hash != user.password_hash:
        raise HTTPException(status_code=401, detail="帳號或密碼錯誤")

    return LoginResponse(success=True, user_id=str(user.id), name=user.name)