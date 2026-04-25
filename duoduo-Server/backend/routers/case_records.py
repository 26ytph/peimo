import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import CaseRecord

router = APIRouter(prefix="/case-records", tags=["case-records"])


class CaseRecordCreate(BaseModel):
    citizen_id: uuid.UUID = Field(..., description="民眾檔案 ID")
    counselor_id: uuid.UUID = Field(..., description="諮商師檔案 ID")
    summary: str | None = Field(None, description="個案摘要", examples=["近期求職壓力較高"])
    current_status: str | None = Field(None, description="目前狀態", examples=["追蹤中"])
    counselor_note: str | None = Field(None, description="諮商師備註", examples=["下次安排履歷健檢"])


class CaseRecordUpdate(BaseModel):
    summary: str | None = Field(None, description="更新個案摘要")
    current_status: str | None = Field(None, description="更新目前狀態")
    counselor_note: str | None = Field(None, description="更新諮商師備註")


class CaseRecordResponse(BaseModel):
    id: uuid.UUID
    citizen_id: uuid.UUID
    counselor_id: uuid.UUID
    summary: str | None
    current_status: str | None
    counselor_note: str | None
    created_at: datetime
    updated_at: datetime


@router.get(
    "",
    response_model=list[CaseRecordResponse],
    summary="列出個案紀錄",
    description="取得所有個案紀錄，依建立時間新到舊排序。",
    response_description="個案紀錄清單。",
)
async def list_case_records(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CaseRecord).order_by(CaseRecord.created_at.desc()))
    return result.scalars().all()


@router.get(
    "/{case_id}",
    response_model=CaseRecordResponse,
    summary="查詢單一個案紀錄",
    description="依 case_id 查詢單筆個案。",
    response_description="個案紀錄內容。",
)
async def get_case_record(case_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    case_record = await db.get(CaseRecord, case_id)
    if not case_record:
        raise HTTPException(status_code=404, detail="Case record not found")
    return case_record


@router.post(
    "",
    response_model=CaseRecordResponse,
    status_code=201,
    summary="建立個案紀錄",
    description="新增一筆個案紀錄。\n\n使用方式：提供 citizen_id 與 counselor_id，其他欄位可選。",
    response_description="新建立的個案紀錄。",
)
async def create_case_record(req: CaseRecordCreate, db: AsyncSession = Depends(get_db)):
    case_record = CaseRecord(
        citizen_id=req.citizen_id,
        counselor_id=req.counselor_id,
        summary=req.summary,
        current_status=req.current_status,
        counselor_note=req.counselor_note,
    )
    db.add(case_record)
    await db.flush()
    return case_record


@router.patch(
    "/{case_id}",
    response_model=CaseRecordResponse,
    summary="更新個案紀錄",
    description="部分更新個案摘要、狀態或備註。",
    response_description="更新後的個案紀錄。",
)
async def update_case_record(case_id: uuid.UUID, req: CaseRecordUpdate, db: AsyncSession = Depends(get_db)):
    case_record = await db.get(CaseRecord, case_id)
    if not case_record:
        raise HTTPException(status_code=404, detail="Case record not found")

    for field, value in req.model_dump(exclude_unset=True).items():
        setattr(case_record, field, value)

    await db.flush()
    return case_record


@router.delete(
    "/{case_id}",
    status_code=204,
    summary="刪除個案紀錄",
    description="刪除指定個案紀錄。",
    response_description="刪除成功（無內容）。",
)
async def delete_case_record(case_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    case_record = await db.get(CaseRecord, case_id)
    if not case_record:
        raise HTTPException(status_code=404, detail="Case record not found")
    await db.delete(case_record)
