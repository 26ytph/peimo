# 青年局課程活動報名系統爬蟲：爬取開放中的課程與活動
# detail 頁面沒有課程詳情，從列表頁直接提取資訊
import logging
import re

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

BASE_URL = "https://www.class.tcyd.gov.taipei"
LIST_URL = "/participate/?node=0"


def crawl() -> list[dict]:
    """爬取青年局課程活動報名系統的課程列表。"""
    results = []
    seen_nodes = set()

    try:
        url = f"{BASE_URL}{LIST_URL}"
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")

        items = soup.select("a[href*='mode=detail']")
        for item in items:
            href = item.get("href", "")
            # 提取 node ID 去重
            node_match = re.search(r"node=(\d+)", href)
            if not node_match:
                continue
            node_id = node_match.group(1)
            if node_id in seen_nodes:
                continue
            seen_nodes.add(node_id)

            text = item.get_text(strip=True)
            if not text or len(text) < 5:
                continue
            # 跳過只有「報名狀態」文字的連結
            if text in ("現場報名", "開放報名中", "尚未開放報名", "額滿"):
                continue

            # 解析格式：日期至日期 課程名稱 人數 免費/金額 報名狀態
            # 例如：2026-05-10至2026-05-10青年學堂【大小孩劇樂部】952免費
            date_match = re.match(r"(\d{4}-\d{2}-\d{2})至(\d{4}-\d{2}-\d{2})", text)
            date_range = ""
            title = text
            if date_match:
                date_range = f"{date_match.group(1)} 至 {date_match.group(2)}"
                title = text[len(date_match.group(0)):]

            # 嘗試分離名稱和其他資訊
            price = "免費" if "免費" in title else ""
            # 移除尾部的數字（人數）和「免費」
            clean_title = re.sub(r"\d+免費$", "", title).strip()
            if not clean_title:
                clean_title = title

            detail_url = f"{BASE_URL}/?mode=detail&node={node_id}"

            content_parts = [f"【{clean_title}】"]
            if date_range:
                content_parts.append(f"日期：{date_range}")
            if price:
                content_parts.append(f"費用：{price}")
            content_parts.append(f"報名連結：{detail_url}")

            results.append({
                "title": clean_title,
                "content": "\n".join(content_parts),
                "url": detail_url,
                "source": "taipei_youth_class",
            })

    except Exception:
        logger.exception("爬取青年局課程活動失敗")

    logger.info("青年局課程活動爬取完成，共 %d 筆", len(results))
    return results
