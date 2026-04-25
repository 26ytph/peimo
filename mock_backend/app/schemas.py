"""Pydantic schema 定義，對齊 iOS 端 CloudModels.swift。"""
from __future__ import annotations
from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4
from pydantic import BaseModel, Field


# ---------- Enums ----------
class ResourceCategory(str, Enum):
    job_intern = "職缺/實習"
    course = "課程/活動"
    competition = "競賽/計劃"
    startup = "創業資源"
    overseas = "國外資源"


class CounselorStatus(str, Enum):
    available = "可預約"
    offline = "離線"
    in_session = "諮商中"


class ChatSender(str, Enum):
    user = "user"
    ai = "ai"
    counselor = "counselor"


class SwipeDirection(str, Enum):
    left = "left"   # pass
    right = "right"  # like


# ---------- Models ----------
class YouthProfile(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    name: str
    age: int
    school: str
    major: str
    location: str
    bio: str = ""
    interests: list[str] = []
    avatarImage: Optional[str] = None    # 圖片檔名（存 uploads/）
    cvFileName: Optional[str] = None
    assignedCounselorId: Optional[UUID] = None


class YouthProfileUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    school: Optional[str] = None
    major: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    interests: Optional[list[str]] = None


class ResourceCard(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    title: str
    organization: str
    category: ResourceCategory
    summary: str
    description: str
    deadline: Optional[str] = None
    amount: Optional[str] = None
    location: Optional[str] = None
    tags: list[str] = []
    url: Optional[str] = None


class Counselor(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    name: str
    title: str
    avatarImage: Optional[str] = None
    specialties: list[str]
    status: CounselorStatus
    bio: str


class Appointment(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    youthId: UUID
    youthName: str
    youthAvatar: str
    requestedAt: datetime
    topic: str
    aiSummary: str
    keywords: list[str]
    isNew: bool = True


class CaseTag(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    name: str
    colorHex: str


class CounselingCase(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    youthId: UUID
    youthName: str
    youthAvatar: str
    lastContact: datetime
    tags: list[CaseTag]
    statusNote: str
    recommendedResourceIds: list[UUID]


class ChatMessage(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    sender: ChatSender
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    attachedResourceId: Optional[UUID] = None


# ---------- Request / Response ----------
class SwipeRequest(BaseModel):
    direction: SwipeDirection


class ChatRequest(BaseModel):
    content: str


class AddTagRequest(BaseModel):
    tagId: UUID


class RecommendRequest(BaseModel):
    resourceId: UUID


# ---------- Application / Counselor Match ----------
class ApplicationStatus(str, Enum):
    none = "未申請"
    applying = "申請中"
    accepted = "報名成功"


class CounselorMatchStatus(str, Enum):
    none = "未申請"
    applied = "已申請"
    scheduled = "已安排"
    in_progress = "諮商中"


class ApplicationStatusResponse(BaseModel):
    resourceId: UUID
    status: ApplicationStatus


class CounselorMatchResponse(BaseModel):
    counselorId: UUID
    status: CounselorMatchStatus
