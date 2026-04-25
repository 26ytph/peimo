import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class CaseRecord(Base):
    __tablename__ = "case_records"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    citizen_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("citizen_profiles.id"), nullable=False)
    counselor_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("counselor_profiles.id"), nullable=False)

    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    current_status: Mapped[str | None] = mapped_column(String(100), nullable=True)
    counselor_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class CaseTag(Base):
    __tablename__ = "case_tags"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)


class CaseTagLink(Base):
    __tablename__ = "case_tag_links"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    case_record_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("case_records.id"), nullable=False)
    tag_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("case_tags.id"), nullable=False)