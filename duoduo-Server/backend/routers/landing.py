"""Landing Page 對話蒐集：逐步補齊青年檔案缺漏欄位"""
import json
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import CitizenProfile, User, ChatSession, ChatMessage
from ..services import llm

router = APIRouter(prefix="/landing", tags=["landing"])

FOLLOWUP_MAX_ROUNDS = 2
META_SENDER_TYPE = "landing_meta"

REQUIRED_PROFILE_FIELDS = [
    "age",
    "location",
    "school",
    "education_level",
    "department",
    "goal",
    "skills",
    "achievement",
    "setback",
    "interests",
    "holland_primary",
    "holland_secondary",
]

class LandingChatRequest(BaseModel):
    user_id: uuid.UUID
    message: str | None = Field(None, description="使用者本輪輸入訊息")


class LandingChatResponse(BaseModel):
    completed: bool
    missing_fields: list[str]
    next_question: str | None
    extracted_fields: dict
    generated_bio: str | None
    profile_data: dict


async def _get_or_create_profile(user_id: uuid.UUID, db: AsyncSession) -> tuple[User, CitizenProfile]:
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


async def _get_or_create_session(citizen_id: uuid.UUID, db: AsyncSession) -> ChatSession:
    result = await db.execute(
        select(ChatSession)
        .where(ChatSession.citizen_id == citizen_id, ChatSession.mode == "landing")
        .order_by(ChatSession.created_at.desc())
    )
    session = result.scalar_one_or_none()
    if not session:
        session = ChatSession(citizen_id=citizen_id, mode="landing")
        db.add(session)
        await db.flush()
    return session


def _is_missing(value) -> bool:
    if value is None:
        return True
    if isinstance(value, str):
        return not value.strip()
    if isinstance(value, list):
        return len(value) == 0
    return False


def _missing_fields(profile: CitizenProfile) -> list[str]:
    return [f for f in REQUIRED_PROFILE_FIELDS if _is_missing(getattr(profile, f, None))]


def _normalize_update(field: str, value):
    if value is None:
        return None

    if field == "age":
        try:
            return int(value)
        except (TypeError, ValueError):
            return None

    if field in ("skills", "interests"):
        if isinstance(value, list):
            return [str(v).strip() for v in value if str(v).strip()]
        if isinstance(value, str):
            parts = value.replace("、", ",").replace("，", ",").split(",")
            return [p.strip() for p in parts if p.strip()]
        return None

    if isinstance(value, str):
        text = value.strip()
        return text if text else None

    return value


def _profile_snapshot(user: User, profile: CitizenProfile) -> dict:
    return {
        "user_id": str(user.id),
        "name": user.name,
        "age": profile.age,
        "location": profile.location,
        "school": profile.school,
        "education_level": profile.education_level,
        "department": profile.department,
        "goal": profile.goal,
        "skills": profile.skills,
        "achievement": profile.achievement,
        "setback": profile.setback,
        "interests": profile.interests,
        "holland_primary": profile.holland_primary,
        "holland_secondary": profile.holland_secondary,
        "bio": profile.bio,
    }


def _message_to_history_item(sender_type: str, message: str) -> dict:
    role = "user" if sender_type == "citizen" else "model"
    return {"role": role, "content": message}


def _select_target_field(
    missing_fields: list[str],
    extracted_fields: dict,
    asked_rounds: dict[str, int],
    last_asked_field: str | None,
) -> tuple[str | None, int]:
    # 只有上一輪目標欄位在本輪有被回答時，才進入第 2 輪追問，避免跳題。
    if last_asked_field and last_asked_field in extracted_fields:
        rounds = asked_rounds.get(last_asked_field, 0)
        if rounds < FOLLOWUP_MAX_ROUNDS:
            return last_asked_field, rounds + 1

    if missing_fields:
        field = missing_fields[0]
        return field, asked_rounds.get(field, 0) + 1

    return None, 0


async def _load_asked_rounds(session_id: uuid.UUID, db: AsyncSession) -> tuple[dict[str, int], str | None]:
    result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.session_id == session_id, ChatMessage.sender_type == META_SENDER_TYPE)
        .order_by(ChatMessage.created_at)
    )
    rounds: dict[str, int] = {}
    last_field: str | None = None
    for meta in result.scalars().all():
        try:
            payload = json.loads(meta.message)
        except json.JSONDecodeError:
            continue
        field = payload.get("field")
        round_no = payload.get("round")
        if isinstance(field, str) and isinstance(round_no, int):
            rounds[field] = max(rounds.get(field, 0), round_no)
            last_field = field
    return rounds, last_field


async def _save_asked_round_meta(
    session_id: uuid.UUID,
    field: str,
    round_no: int,
    db: AsyncSession,
) -> None:
    meta = ChatMessage(
        session_id=session_id,
        sender_type=META_SENDER_TYPE,
        message=json.dumps({"field": field, "round": round_no}, ensure_ascii=False),
    )
    db.add(meta)


@router.post(
    "/chat",
    response_model=LandingChatResponse,
    summary="Landing 對話補齊青年資料",
)
async def landing_chat(req: LandingChatRequest, db: AsyncSession = Depends(get_db)):
    user, profile = await _get_or_create_profile(req.user_id, db)
    session = await _get_or_create_session(profile.id, db)

    history_result = await db.execute(
        select(ChatMessage)
        .where(ChatMessage.session_id == session.id)
        .order_by(ChatMessage.created_at)
    )
    history_msgs = history_result.scalars().all()
    conversation = [
        _message_to_history_item(m.sender_type, m.message)
        for m in history_msgs
        if m.sender_type != META_SENDER_TYPE
    ]
    asked_rounds, last_asked_field = await _load_asked_rounds(session.id, db)

    missing_before = _missing_fields(profile)
    extracted_fields: dict = {}

    if req.message and req.message.strip() and missing_before:
        user_msg = ChatMessage(session_id=session.id, sender_type="citizen", message=req.message.strip())
        db.add(user_msg)
        conversation.append(_message_to_history_item("citizen", req.message.strip()))

        try:
            parsed = await llm.extract_profile_updates(req.message, REQUIRED_PROFILE_FIELDS)
        except Exception:
            parsed = {}

        for field, raw_value in parsed.items():
            if field not in REQUIRED_PROFILE_FIELDS:
                continue
            value = _normalize_update(field, raw_value)
            if _is_missing(value):
                continue
            setattr(profile, field, value)
            extracted_fields[field] = value

        await db.flush()

    missing_after = _missing_fields(profile)
    profile_data = _profile_snapshot(user, profile)
    target_field, round_no = _select_target_field(
        missing_after,
        extracted_fields,
        asked_rounds,
        last_asked_field,
    )

    if not target_field:
        generated_bio = None
        if not missing_after:
            try:
                generated_bio = await llm.generate_profile_bio(profile_data)
            except Exception:
                generated_bio = (
                    f"{user.name} 目前以 {profile.goal or '職涯發展'} 為目標，"
                    "已累積一定技能與興趣方向，正在穩定前進。"
                )

            profile.bio = generated_bio
            await db.flush()

        return LandingChatResponse(
            completed=not missing_after,
            missing_fields=missing_after,
            next_question=None,
            extracted_fields=extracted_fields,
            generated_bio=generated_bio,
            profile_data=_profile_snapshot(user, profile),
        )

    try:
        question_payload = await llm.generate_landing_question(
            profile_data=profile_data,
            target_field=target_field,
            missing_fields=missing_after,
            conversation=conversation,
            asked_round=round_no,
            max_rounds=FOLLOWUP_MAX_ROUNDS,
        )
    except Exception:
        question_payload = {}

    next_question = question_payload.get("next_question") or f"可以多說說你的{target_field}嗎？"
    assistant_msg = ChatMessage(session_id=session.id, sender_type="ai", message=next_question)
    db.add(assistant_msg)
    await _save_asked_round_meta(session.id, target_field, round_no, db)
    await db.flush()

    return LandingChatResponse(
        completed=False,
        missing_fields=missing_after,
        next_question=next_question,
        extracted_fields=extracted_fields,
        generated_bio=None,
        profile_data=profile_data,
    )
