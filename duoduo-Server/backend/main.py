# FastAPI 應用入口：掛載所有路由，啟動時建立資料表
from contextlib import asynccontextmanager
from importlib import import_module
from hashlib import sha256
import logging
import uuid

from fastapi import FastAPI
from sqlalchemy import text

from .db import engine
from . import models as _models
from .models import Base

logger = logging.getLogger(__name__)


async def bootstrap_users_schema() -> None:
    async with engine.begin() as conn:
        # 舊版 users 結構可能缺少 role/email/avatar_url，啟動時補齊
        await conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(30)"))
        await conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255)"))
        await conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500)"))

        # 既有資料沒有 role 時，預設補 citizen，避免 API response 驗證失敗
        await conn.execute(text("UPDATE users SET role = 'citizen' WHERE role IS NULL"))

        # 舊資料表若 account/email 尚未有唯一索引，補上
        await conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_account ON users (account)"))
        await conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_email ON users (email)"))

        # 初始化預設青年使用者：威威
        await conn.execute(
            text(
                """
                INSERT INTO users (id, account, password_hash, role, name, stage)
                VALUES (:id, :account, :password_hash, :role, :name, :stage)
                ON CONFLICT (account) DO NOTHING
                """
            ),
            {
                "id": str(uuid.uuid4()),
                "account": "wiwi",
                "password_hash": sha256("wiwi".encode("utf-8")).hexdigest(),
                "role": "citizen",
                "name": "威威",
                "stage": "在學",
            },
        )

        # 舊版 citizen_profiles 可能缺少新欄位，啟動時補齊
        await conn.execute(text("ALTER TABLE citizen_profiles ADD COLUMN IF NOT EXISTS achievement TEXT"))
        await conn.execute(text("ALTER TABLE citizen_profiles ADD COLUMN IF NOT EXISTS setback TEXT"))
        await conn.execute(text("ALTER TABLE citizen_profiles ADD COLUMN IF NOT EXISTS counselor_list JSON"))
        await conn.execute(text("ALTER TABLE citizen_profiles ALTER COLUMN holland_primary TYPE TEXT"))
        await conn.execute(text("ALTER TABLE citizen_profiles ALTER COLUMN holland_secondary TYPE TEXT"))


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 啟動時自動建表（開發用，正式環境建議用 Alembic migration）
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await bootstrap_users_schema()
    yield
    await engine.dispose()


app = FastAPI(
    title="朵朵 DuoDuo API",
    description="AI 職涯路徑規劃後端服務",
    version="0.1.0",
    openapi_tags=[
        {
            "name": "users",
            "description": "使用者資料管理（建立、查詢、更新、刪除）。",
        },
        {
            "name": "admin-resources",
            "description": "資源資料後台 CRUD。若前台只需查詢推薦，請使用 resources。",
        },
        {
            "name": "case-records",
            "description": "個案紀錄管理（供諮詢流程使用）。",
        },
        {
            "name": "resources",
            "description": "前台資源語意查詢（RAG）。",
        },
        {
            "name": "landing",
            "description": "Landing 頁資料蒐集對話與個人簡介生成。",
        },
    ],
    lifespan=lifespan,
)

for router_name in (
    "users", "resources_crud", "case_records", "path", "resource",
    "youth", "resource_interactions", "counselors", "case_management", "chat_sessions", "landing",
):
    try:
        router_module = import_module(f".routers.{router_name}", package=__package__)
        app.include_router(router_module.router)
    except Exception as exc:
        logger.warning("Skip loading router '%s': %s", router_name, exc)


@app.get(
    "/health",
    tags=["system"],
    summary="健康檢查",
    description="確認 API 服務是否正常運作。\n\n使用方式：直接呼叫本端點，收到 status=ok 代表服務可用。",
    response_description="服務狀態。",
)
async def health_check():
    return {"status": "ok"}
