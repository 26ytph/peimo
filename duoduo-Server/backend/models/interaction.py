import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    citizen_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("citizen_profiles.id"), nullable=False)
    counselor_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("counselor_profiles.id"), nullable=False)

    status: Mapped[str] = mapped_column(String(30), default="pending")
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class CounselorAssignment(Base):
    __tablename__ = "counselor_assignments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    citizen_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("citizen_profiles.id"), nullable=False)
    counselor_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("counselor_profiles.id"), nullable=False)

    status: Mapped[str] = mapped_column(String(30), default="active")  # active / ended
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class ResourceSwipe(Base):
    __tablename__ = "resource_swipes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    citizen_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("citizen_profiles.id"), nullable=False)
    resource_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("resources.id"), nullable=False)

    action: Mapped[str] = mapped_column(String(30), nullable=False)  # like / dislike / save
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Recommendation(Base):
    __tablename__ = "recommendations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    citizen_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("citizen_profiles.id"), nullable=False)
    resource_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("resources.id"), nullable=False)
    counselor_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("counselor_profiles.id"), nullable=True)

    recommender_type: Mapped[str] = mapped_column(String(30), nullable=False)  # ai / counselor
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    score: Mapped[float | None] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())