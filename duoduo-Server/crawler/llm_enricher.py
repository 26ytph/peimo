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
  "summary": "一段精簡摘要（50-100字），只寫這筆資料是什麼、對誰有用，細節放 important_info",
  "category": "從下方分類中選擇最符合的一個主要分類",
  "tags": ["標籤1", "標籤2"],
  "important_info": ["重要資訊1", "重要資訊2"]
}}

## category（必填，僅選一個最主要的分類）：
補助, 貸款, 課程, 競賽, 實習, 就業, 創業, 活動, 場地, 諮詢, 住宅, 國際交流, 其他

## tags 規則（嚴格限制）：
- 最多只能給 2 個標籤，不要超過
- 標籤應描述資料的具體特徵，不要與 category 重複
- 例如：「青年」「職涯」「免費」「線上」「台北市」等
- 不要把所有沾得上邊的標籤都加上去，只保留最核心的

## important_info 規則：
- 列出這筆資料中使用者最需要知道的關鍵資訊
- 例如：截止日期、補助金額、時薪、申請資格、地點、可重複申請（每季/每年）等
- 每條資訊簡短扼要，不超過 30 字
- 最多 5 條
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
            request_options={"timeout": 60},
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
            doc["category"] = result.get("category", "其他")
            tags = result.get("tags", [])
            doc["tags"] = ",".join(tags[:2])
            doc["important_info"] = result.get("important_info", [])
            success += 1
        enriched.append(doc)

        if (i + 1) % 10 == 0:
            logger.info("LLM 增強進度：%d/%d", i + 1, len(docs))

    logger.info("LLM 增強完成，共處理 %d 筆，成功 %d 筆", len(enriched), success)
    return enriched
