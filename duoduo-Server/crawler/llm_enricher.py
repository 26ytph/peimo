# LLM 資料增強：用 Gemini 為爬蟲資料產生標題、標籤與摘要
import json
import logging
import os

import google.generativeai as genai

logger = logging.getLogger(__name__)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

ENRICH_PROMPT = """\
你是台北市青年政策資料整理助手。請為以下原始資料產生結構化摘要。

原始資料：
{raw_content}

請以 JSON 格式回覆，不要附加任何其他文字：
{{
  "title": "簡潔的標題（20字以內）",
  "summary": "一段描述這筆資料核心內容的摘要（100-200字），要保留關鍵資訊如日期、費用、報名方式等",
  "tags": ["標籤1", "標籤2", "標籤3"]
}}

標籤請從以下類別中選擇（可多選）：
創業, 就業, 職涯, 培訓課程, 補助, 貸款, 實習, 志工, 國際交流, 市集, 諮詢輔導, 政策公告, 活動, 青年住宅, 心理健康, 其他
"""


def _get_model():
    if not GEMINI_API_KEY:
        return None
    genai.configure(api_key=GEMINI_API_KEY)
    return genai.GenerativeModel(
        "gemini-2.5-flash",
        generation_config={"temperature": 0.2},
    )


def enrich_single(model, raw_content: str) -> dict | None:
    """對單筆資料做 LLM 增強，回傳 {title, summary, tags}。"""
    try:
        prompt = ENRICH_PROMPT.format(raw_content=raw_content[:1500])
        response = model.generate_content(
            prompt,
            request_options={"timeout": 30},
        )
        text = response.text.strip()
        if text.startswith("```"):
            text = text.split("\n", 1)[1].rsplit("```", 1)[0].strip()
        return json.loads(text)
    except Exception:
        logger.exception("LLM 增強失敗，使用原始資料")
        return None


def enrich_documents(docs: list[dict]) -> list[dict]:
    """批次為文件做 LLM 增強。若無 API key 則跳過。"""
    model = _get_model()
    if not model:
        logger.warning("未設定 GEMINI_API_KEY，跳過 LLM 增強")
        return docs

    enriched = []
    success = 0
    for i, doc in enumerate(docs):
        raw_content = doc.get("content", "")
        if len(raw_content) < 30:
            enriched.append(doc)
            continue

        result = enrich_single(model, raw_content)
        if result:
            doc["title"] = result.get("title", doc.get("title", ""))
            doc["content"] = result.get("summary", raw_content)
            doc["tags"] = ",".join(result.get("tags", []))
            success += 1
        enriched.append(doc)

        if (i + 1) % 10 == 0:
            logger.info("LLM 增強進度：%d/%d", i + 1, len(docs))

    logger.info("LLM 增強完成，共處理 %d 筆，成功 %d 筆", len(enriched), success)
    return enriched
