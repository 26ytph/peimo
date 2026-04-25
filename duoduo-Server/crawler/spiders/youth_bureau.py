# 台北市青年局爬蟲：透過 Nuxt _payload.json 端點取得公告內容
# youth.gov.taipei 為 Vue.js SPA，無法用 requests+BS4 直接爬取
# 但 Nuxt 3 會在 _payload.json 提供預渲染的資料
import logging
import re

import requests

logger = logging.getLogger(__name__)

BASE_URL = "https://youth.gov.taipei"

PAYLOAD_PAGES = [
    "/announcement/news/_payload.json",
    "/announcement/latest-announcement/_payload.json",
]


def _parse_nuxt_payload(data: list) -> list[dict]:
    """解析 Nuxt 3 dehydrated payload 格式，提取 records。"""
    records = []

    # 找到包含 records 欄位的 dict
    for item in data:
        if not isinstance(item, dict) or "records" not in item:
            continue

        rec_list_idx = item["records"]
        rec_indices = data[rec_list_idx] if isinstance(rec_list_idx, int) else rec_list_idx
        if not isinstance(rec_indices, list):
            break

        for idx in rec_indices:
            if idx >= len(data):
                continue
            rec = data[idx]
            if not isinstance(rec, dict):
                continue

            # 解引用欄位值
            def deref(key):
                val_idx = rec.get(key)
                if isinstance(val_idx, int) and val_idx < len(data):
                    return data[val_idx]
                return val_idx

            title = deref("title") or ""
            content_html = deref("content") or ""
            created_time = deref("created_time") or ""
            ay_id = deref("ay_id") or ""

            if not title or title.startswith("-"):
                continue

            # 移除 HTML 標籤
            content_text = re.sub(r"<[^>]+>", "", str(content_html))
            content_text = re.sub(r"&nbsp;", " ", content_text).strip()

            if not content_text:
                continue

            records.append({
                "title": title,
                "content": content_text[:2000],
                "date": str(created_time)[:10],
                "ay_id": str(ay_id),
            })

        break  # 只處理第一個含 records 的 dict

    return records


def crawl() -> list[dict]:
    """透過 Nuxt payload 端點爬取青年局公告。"""
    results = []
    seen_ids = set()

    for path in PAYLOAD_PAGES:
        try:
            url = f"{BASE_URL}{path}"
            resp = requests.get(url, timeout=30)
            resp.raise_for_status()
            payload = resp.json()

            records = _parse_nuxt_payload(payload)
            for rec in records:
                # 去重
                if rec["ay_id"] in seen_ids:
                    continue
                seen_ids.add(rec["ay_id"])

                content = rec["content"]
                if rec["date"]:
                    content = f"[{rec['date']}] {content}"

                results.append({
                    "title": rec["title"],
                    "content": content[:2000],
                    "url": f"{BASE_URL}/announcement/news",
                    "source": "taipei_youth_bureau",
                })

        except Exception:
            logger.exception("爬取青年局 %s 失敗", path)

    logger.info("青年局爬取完成，共 %d 筆", len(results))
    return results
