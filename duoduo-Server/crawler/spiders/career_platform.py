# 青年職涯發展平臺爬蟲：爬取 tpyd.104.com.tw 的服務資訊頁面
# 注意：此網站為 SPA（前端渲染），大部分內容無法直接用 requests 取得
# 這裡先爬取可用的靜態頁面，未來若需要動態內容可改用 Selenium
import logging

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

BASE_URL = "https://tpyd.104.com.tw"

# 靜態可爬的頁面（SPA 頁面需另外處理）
STATIC_PAGES = [
    {"url": f"{BASE_URL}/career", "title": "職涯諮詢", "source": "tpyd_career"},
    {"url": f"{BASE_URL}/startup", "title": "創業諮詢", "source": "tpyd_startup"},
    {"url": f"{BASE_URL}/spaces", "title": "創業找空間", "source": "tpyd_spaces"},
    {"url": f"{BASE_URL}/internship", "title": "市府工讀", "source": "tpyd_internship"},
    {"url": f"{BASE_URL}/fairs", "title": "青年找市集", "source": "tpyd_fairs"},
    {"url": f"{BASE_URL}/jobs", "title": "臺北超優職", "source": "tpyd_jobs"},
    {"url": f"{BASE_URL}/studies", "title": "職涯進修補助", "source": "tpyd_studies"},
]


def crawl() -> list[dict]:
    """嘗試爬取青年職涯發展平臺各頁面。"""
    results = []

    for page in STATIC_PAGES:
        try:
            resp = requests.get(page["url"], timeout=30)
            resp.raise_for_status()
            soup = BeautifulSoup(resp.text, "html.parser")

            # SPA 頁面可能只有空殼，檢查是否有實際內容
            body = soup.select_one("body")
            if not body:
                continue

            # 移除 script/style 標籤
            for tag in body.select("script, style, noscript"):
                tag.decompose()

            text = body.get_text(separator="\n", strip=True)

            # 如果內容太少，代表是 SPA 空殼
            if len(text) < 100:
                logger.info("頁面 %s 可能為 SPA，內容不足，跳過", page["url"])
                continue

            results.append({
                "title": page["title"],
                "content": f"【{page['title']}】\n{text}"[:2000],
                "url": page["url"],
                "source": page["source"],
            })

        except Exception:
            logger.exception("爬取 %s 失敗", page["url"])

    logger.info("青年職涯發展平臺爬取完成，共 %d 筆", len(results))
    return results
