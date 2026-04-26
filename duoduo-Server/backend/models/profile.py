import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


class CitizenProfile(Base):
    __tablename__ = "citizen_profiles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), unique=True, nullable=False)

    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    location: Mapped[str | None] = mapped_column(String(100), nullable=True)
    school: Mapped[str | None] = mapped_column(String(100), nullable=True)
    education_level: Mapped[str | None] = mapped_column(String(100), nullable=True)
    department: Mapped[str | None] = mapped_column(String(100), nullable=True)
    goal: Mapped[str | None] = mapped_column(String(50), nullable=True)
    skills: Mapped[list | None] = mapped_column(JSON, nullable=True)
    achievement: Mapped[str | None] = mapped_column(Text, nullable=True)
    setback: Mapped[str | None] = mapped_column(Text, nullable=True)
    interests: Mapped[list | None] = mapped_column(JSON, nullable=True)
    holland_primary: Mapped[str | None] = mapped_column(Text, nullable=True)
    holland_secondary: Mapped[str | None] = mapped_column(Text, nullable=True)
    counselor_list: Mapped[list | None] = mapped_column(JSON, nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
    prefer_resources: Mapped[str | None] = mapped_column(String(200), nullable=True)  # 偏好資源搜尋關鍵字
    career_path: Mapped[list | None] = mapped_column(JSON, nullable=True)  # LLM 生成的職涯階段

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user: Mapped["User"] = relationship(back_populates="citizen_profile")


class CounselorProfile(Base):
    __tablename__ = "counselor_profiles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), unique=True, nullable=False)

    title: Mapped[str | None] = mapped_column(String(100), nullable=True)
    specialty: Mapped[list | None] = mapped_column(JSON, nullable=True)
    introduction: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="offline")
    years_experience: Mapped[int | None] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user: Mapped["User"] = relationship(back_populates="counselor_profile")