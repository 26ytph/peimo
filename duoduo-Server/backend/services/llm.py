# LLM 服務：封裝 Gemini API 的路徑生成、對話、複雜度評估功能
import json
import logging

import google.generativeai as genai

from ..config import settings

logger = logging.getLogger(__name__)

genai.configure(api_key=settings.GEMINI_API_KEY)
model = genai.GenerativeModel(
    "gemini-2.5-flash",
    generation_config={"temperature": 0.5},
)

PATH_SYSTEM_PROMPT = """\
你是「朵朵 DuoDuo」的台北青年職涯顧問。
根據使用者的夢想與背景資料，規劃一條完整的職涯發展路徑。

規則：
1. 根據使用者的現況與目標，拆分成多個「階段」（不限數量，通常 3~6 個階段）。
2. 每個階段代表一個具體的成長里程碑，而非固定的短中長期。
3. 階段的粒度由目標複雜度決定——簡單目標可以少一點，複雜目標可以多一點。
4. 每個階段的 resources 欄位，請填入可對應的台北市政府青年資源名稱或類型（如具體計畫名稱、培訓課程、補助計畫、創業輔導、實習媒合等）。若下方有提供「可參考的政府資源」，請優先引用。

請以下列 JSON 格式回覆，不要附加任何其他文字：
[
  {
    "title": "階段名稱（簡短，例如：探索興趣與定向）",
    "content": "這個階段要做什麼、為什麼重要、預期成果（2~4 句）",
    "resources": ["資源名稱或類型 1", "資源名稱或類型 2"]
  }
]
"""

CHAT_SYSTEM_PROMPT = """\
你是「朵朵 DuoDuo」的 AI 職涯諮商師，專門服務台北地區的青年。
請根據以下政策資源片段來回答使用者的問題，若資源片段中有相關資訊請引用並附上來源。
語氣親切、專業，以繁體中文回覆。

【相關政策資源】
{rag_context}
"""

ASSESS_SYSTEM_PROMPT = """\
你是一位心理健康評估專家。閱讀以下對話紀錄，判斷使用者是否有以下情況：
1. 嚴重情緒困擾（如自殘、自殺意念）
2. 職涯問題已超出 AI 能力範圍（如法律糾紛、嚴重職場霸凌）
3. 使用者明確要求與真人諮商師對話

若符合任一條件，回覆 "YES"，否則回覆 "NO"。只回覆 YES 或 NO。
"""

PROFILE_EXTRACT_PROMPT = """\
你是資料抽取助手。請從使用者訊息中擷取可填入青年檔案的欄位。

規則：
1. 只回傳 JSON 物件，不要任何額外文字。
2. 只能輸出允許欄位中的鍵；沒有資訊就不要輸出該鍵。
3. `skills`、`interests` 請輸出陣列。
4. `age` 請輸出整數。
5. 不確定時不要猜測。

允許欄位：
{allowed_fields}
"""

PROFILE_BIO_PROMPT = """\
你是「朵朵 DuoDuo」職涯助理。請根據以下青年資料，產生 120~180 字的繁體中文個人簡介。

規則：
1. 語氣真誠、具行動感。
2. 要自然涵蓋：背景、興趣/技能、目標、目前狀態。
3. 不要使用條列，輸出單一段落。

青年資料(JSON)：
{profile_json}
"""

LANDING_FIELD_FALLBACK_QUESTION = {
    "age": "你今年幾歲？",
    "location": "你目前主要活動地點在哪裡？",
    "school": "你的畢業學校或目前就讀學校是？",
    "education_level": "你的教育程度是什麼？",
    "department": "你的科系或主修是什麼？",
    "goal": "你目前最想達成的目標是什麼？",
    "skills": "你目前最有把握的技能有哪些？",
    "achievement": "最近最有成就感的一件事是什麼？",
    "setback": "最近讓你最挫折的一件事是什麼？",
    "interests": "你平常最投入的興趣有哪些？",
    "holland_primary": "你的首要何倫碼是什麼？",
    "holland_secondary": "你的次要何倫碼是什麼？",
}

LANDING_FIELD_KEYWORDS = {
    "age": ["幾歲", "年齡"],
    "location": ["地點", "哪裡", "所在地", "活動"],
    "school": ["學校", "畢業"],
    "education_level": ["教育", "學歷"],
    "department": ["科系", "主修", "系"],
    "goal": ["目標", "想", "達成"],
    "skills": ["技能", "能力", "擅長"],
    "achievement": ["成就", "做到", "完成", "成果"],
    "setback": ["挫折", "失落", "卡關", "困難"],
    "interests": ["興趣", "喜歡", "投入"],
    "holland_primary": ["何倫", "首要"],
    "holland_secondary": ["何倫", "次要"],
}

LANDING_QUESTION_PROMPT = """\
你是「朵朵 DuoDuo」的 Landing 問答引導員。你的任務不是填表，而是像真人一樣追問，幫助蒐集更完整、可用來描寫青年經歷的資訊。

目標：
1. 你只能針對指定欄位 `target_field` 發問，不能問其他欄位。
2. 問題要短，最多 25 個中文字。
3. 一次只問一個問題，不可有第二個子問題，不可條列。
4. 對於 achievement / setback，仍要引導細節，但只能聚焦在該欄位。
5. 請回傳 JSON 物件，不要附加任何其他文字。
6. 若 asked_round > 1，請用「補充追問」語氣，延續同一欄位細節。

輸出格式：
{{
    "next_field": "必須等於 target_field",
    "next_question": "要問使用者的一句話",
    "why": "簡短說明為什麼這題最值得問"
}}

target_field：
{target_field}

目前追問輪次：
{asked_round}/{max_rounds}

可追問欄位（僅供背景）：
{missing_fields}

目前資料：
{profile_json}

對話歷程：
{conversation}
"""


async def generate_path(dream: str, background: dict, rag_context: str = "") -> list[dict]:
    """根據夢想與背景生成多階段職涯路徑 JSON。"""
    user_prompt = f"夢想：{dream}\n背景：{json.dumps(background, ensure_ascii=False)}"
    if rag_context:
        user_prompt += f"\n\n【可參考的政府資源】\n{rag_context}"

    response = await model.generate_content_async(
        [{"role": "user", "parts": [PATH_SYSTEM_PROMPT + "\n\n" + user_prompt]}]
    )
    text = response.text.strip()
    # 移除 markdown code fence
    if text.startswith("```"):
        text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()
    stages = json.loads(text)
    # 確保每個階段都有必要欄位
    for stage in stages:
        stage.setdefault("title", "")
        stage.setdefault("content", "")
        stage.setdefault("resources", [])
    return stages


async def chat(history: list[dict], user_message: str, rag_context: str = "") -> str:
    """帶 RAG 上下文的對話。"""
    system = CHAT_SYSTEM_PROMPT.format(rag_context=rag_context or "（無相關資源）")

    contents = [{"role": "user", "parts": [system]}]
    for msg in history:
        contents.append({"role": msg["role"], "parts": [msg["content"]]})
    contents.append({"role": "user", "parts": [user_message]})

    response = await model.generate_content_async(contents)
    return response.text


async def assess_complexity(transcript: str) -> bool:
    """判斷對話是否需要轉介真人諮商師。"""
    response = await model.generate_content_async(
        [{"role": "user", "parts": [ASSESS_SYSTEM_PROMPT + "\n\n" + transcript]}]
    )
    return response.text.strip().upper() == "YES"


def _strip_code_fence(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()
    return text


def _safe_json_loads(text: str) -> dict:
    text = _strip_code_fence(text)
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return {}
    return data if isinstance(data, dict) else {}


def _landing_fallback_question(target_field: str) -> str:
    return LANDING_FIELD_FALLBACK_QUESTION.get(target_field, f"可以多說說你的{target_field}嗎？")


def _is_question_on_target(target_field: str, question: str) -> bool:
    if not question:
        return False
    keywords = LANDING_FIELD_KEYWORDS.get(target_field, [])
    if not keywords:
        return True
    return any(k in question for k in keywords)


async def extract_profile_updates(message: str, allowed_fields: list[str]) -> dict:
    """從單次訊息抽取青年檔案欄位。"""
    if not message.strip() or not allowed_fields:
        return {}

    prompt = PROFILE_EXTRACT_PROMPT.format(allowed_fields=", ".join(allowed_fields))
    response = await model.generate_content_async(
        [{"role": "user", "parts": [prompt + "\n\n使用者訊息：" + message]}]
    )
    return _safe_json_loads(response.text)


async def generate_landing_question(
    profile_data: dict,
    target_field: str,
    missing_fields: list[str],
    conversation: list[dict],
    asked_round: int = 1,
    max_rounds: int = 2,
) -> dict:
    """根據目前資料與歷程產生下一題 landing 問題。"""
    if not missing_fields or not target_field:
        return {}

    conversation_text = "\n".join(
        f"{msg['role']}: {msg['content']}" for msg in conversation[-12:]
    ) or "（尚無對話）"
    prompt = LANDING_QUESTION_PROMPT.format(
        target_field=target_field,
        asked_round=asked_round,
        max_rounds=max_rounds,
        missing_fields=", ".join(missing_fields),
        profile_json=json.dumps(profile_data, ensure_ascii=False),
        conversation=conversation_text,
    )
    response = await model.generate_content_async(
        [{"role": "user", "parts": [prompt]}]
    )
    data = _safe_json_loads(response.text)
    next_question = str(data.get("next_question", "")).strip()
    if not next_question:
        next_question = _landing_fallback_question(target_field)

    if len(next_question) > 40:
        next_question = next_question[:40].rstrip("，。,. ") + "？"

    if not _is_question_on_target(target_field, next_question):
        next_question = _landing_fallback_question(target_field)

    return {
        "next_field": target_field,
        "next_question": next_question,
        "why": str(data.get("why", "")).strip(),
    }


async def generate_profile_bio(profile_data: dict) -> str:
    """依青年檔案生成個人簡介。"""
    prompt = PROFILE_BIO_PROMPT.format(
        profile_json=json.dumps(profile_data, ensure_ascii=False)
    )
    response = await model.generate_content_async(
        [{"role": "user", "parts": [prompt]}]
    )
    return response.text.strip()
