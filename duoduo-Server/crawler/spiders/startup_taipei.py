# 創業台北爬蟲：爬取最新消息、活動訊息、創業課程
import logging

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

BASE_URL = "https://www.startup.taipei"

# 要爬的列表頁（typeid=1 最新消息, typeid=2 活動訊息）
LIST_PAGES = [
    {"path": "/index.php?action=news&typeid=1", "source": "startup_taipei_news"},
    {"path": "/index.php?action=news&typeid=2", "source": "startup_taipei_events"},
    {"path": "/index.php?action=course&cid=76", "source": "startup_taipei_beginner_course"},
    {"path": "/index.php?action=course&cid=77", "source": "startup_taipei_advanced_course"},
]


def crawl() -> list[dict]:
    """爬取創業台北的消息、活動與課程。"""
    results = []

    for page_info in LIST_PAGES:
        for page_num in range(1, 4):  # 最多爬 3 頁
            try:
                url = f"{BASE_URL}{page_info['path']}"
                if page_num > 1:
                    url += f"&p={page_num}"

                resp = requests.get(url, timeout=30)
                resp.raise_for_status()
                soup = BeautifulSoup(resp.text, "html.parser")

                # 找所有連到 detail 頁的連結
                items = soup.select("a[href*='news_detail'], a[href*='course_detail']")
                if not items:
                    items = soup.select("a:has(h3)")
                if not items:
                    break

                for item in items:
                    title_tag = item.select_one("h3") or item.select_one("h4")
                    title = title_tag.get_text(strip=True) if title_tag else item.get_text(strip=True)[:100]
                    if not title:
                        continue

                    # 跳過只有短標題的分類連結（如「勞動局」「青年局」等導覽項目）
                    p_tag = item.select_one("p")
                    full_text = item.get_text(strip=True)
                    if len(full_text) < 15 and not item.select_one("span"):
                        continue

                    href = item.get("href", "")
                    detail_url = href if href.startswith("http") else f"{BASE_URL}/{href.lstrip('/')}"

                    # 取摘要與日期
                    summary = p_tag.get_text(strip=True) if p_tag else ""
                    span_tag = item.select_one("span")
                    date = span_tag.get_text(strip=True) if span_tag else ""

                    # 取詳情
                    detail = _fetch_detail(detail_url)
                    content = detail or summary or title
                    if date:
                        content = f"[{date}] {content}"

                    results.append({
                        "title": title,
                        "content": content[:2000],
                        "url": detail_url,
                        "source": page_info["source"],
                    })

            except Exception:
                logger.exception("爬取創業台北 %s 第 %d 頁失敗", page_info["path"], page_num)
                break

    logger.info("創業台北爬取完成，共 %d 筆", len(results))
    return results


def _fetch_detail(url: str) -> str:
    """取得詳情頁內文。"""
    try:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")

        # 移除 header/footer/nav 避免汙染內容
        for tag in soup.select("header, footer, nav, script, style, .header, .footer"):
            tag.decompose()

        # 優先從 #mainContent 提取
        main = soup.select_one("#mainContent")
        if main:
            text = main.get_text(strip=True)
            # 移除開頭的麵包屑導覽（回首頁...）
            for prefix in ["回首頁訊息公告最新消息", "回首頁訊息公告活動訊息", "回首頁課程資訊"]:
                if text.startswith(prefix):
                    text = text[len(prefix):]
            if len(text) > 50:
                return text[:2000]

        for selector in [".startup-section", ".news-content", ".course-content", "article", ".content"]:
            div = soup.select_one(selector)
            if div and len(div.get_text(strip=True)) > 50:
                return div.get_text(strip=True)[:2000]

    except Exception:
        logger.warning("無法取得詳情頁：%s", url)
    return ""
