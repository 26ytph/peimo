# Open Taipei API 爬蟲：拉取台北市公開資料集
import logging

import requests

logger = logging.getLogger(__name__)

BASE_URL = "https://data.taipei/api/v1/dataset"

# Dataset ID（placeholder，需替換為實際 dataset ID）
DATASETS = {
    "free_digital_courses": "PLACEHOLDER_DATASET_ID_1",
    "elearning_courses": "PLACEHOLDER_DATASET_ID_2",
}


def crawl() -> list[dict]:
    """從 Open Taipei 拉取課程相關資料集。"""
    results = []

    for name, dataset_id in DATASETS.items():
        try:
            resp = requests.get(
                f"{BASE_URL}/{dataset_id}",
                params={"scope": "resourceAquire", "limit": 100},
                timeout=30,
            )
            resp.raise_for_status()
            data = resp.json()

            records = data.get("result", {}).get("results", [])
            for record in records:
                title = record.get("title") or record.get("課程名稱") or record.get("name", "")
                content = record.get("description") or record.get("課程說明") or str(record)
                url = record.get("url") or record.get("連結") or ""

                results.append({
                    "title": title,
                    "content": f"{title}\n{content}"[:2000],
                    "url": url,
                    "source": f"open_taipei_{name}",
                })

        except Exception:
            logger.exception("拉取 Open Taipei 資料集 %s 失敗", name)

    logger.info("Open Taipei 爬取完成，共 %d 筆", len(results))
    return results
