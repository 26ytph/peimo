import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import Resource

router = APIRouter(prefix="/admin/resources", tags=["admin-resources"])


class ResourceCreate(BaseModel):
    title: str = Field(..., description="資源標題", examples=["台北青年職涯工作坊"])
    content: str = Field(..., description="資源內容", examples=["提供履歷健檢與模擬面試"])
    tags: list[str] | None = Field(None, description="標籤", examples=[["職涯", "履歷"]])
    source: str | None = Field(None, description="來源", examples=["台北市青年局"])
    url: str | None = Field(None, description="原始連結", examples=["https://example.com/resource"])


class ResourceUpdate(BaseModel):
    title: str | None = Field(None, description="資源標題")
    content: str | None = Field(None, description="資源內容")
    tags: list[str] | None = Field(None, description="標籤")
    source: str | None = Field(None, description="來源")
    url: str | None = Field(None, description="原始連結")


class ResourceResponse(BaseModel):
    id: uuid.UUID
    title: str
    content: str
    tags: list | None
    source: str | None
    url: str | None
    created_at: datetime
    updated_at: datetime


@router.get("", response_model=list[ResourceResponse], summary="列出資源（後台）")
async def list_resources(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Resource).order_by(Resource.created_at.desc()))
    return result.scalars().all()


@router.get("/{resource_id}", response_model=ResourceResponse, summary="查詢單一資源")
async def get_resource(resource_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    resource = await db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    return resource


@router.post("", response_model=ResourceResponse, status_code=201, summary="新增資源")
async def create_resource(req: ResourceCreate, db: AsyncSession = Depends(get_db)):
    resource = Resource(
        title=req.title,
        content=req.content,
        tags=req.tags,
        source=req.source,
        url=req.url,
    )
    db.add(resource)
    await db.flush()
    return resource


@router.patch("/{resource_id}", response_model=ResourceResponse, summary="更新資源")
async def update_resource(resource_id: uuid.UUID, req: ResourceUpdate, db: AsyncSession = Depends(get_db)):
    resource = await db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    for field, value in req.model_dump(exclude_unset=True).items():
        setattr(resource, field, value)
    await db.flush()
    return resource


@router.delete("/{resource_id}", status_code=204, summary="刪除資源")
async def delete_resource(resource_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    resource = await db.get(Resource, resource_id)
    if not resource:
        raise HTTPException(status_code=404, detail="Resource not found")
    await db.delete(resource)
