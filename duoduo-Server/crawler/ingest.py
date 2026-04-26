# 資料寫入：將爬蟲結果轉成 embedding 寫入 ChromaDB
import logging
import uuid

from spiders import career_platform, class_tcyd, open_taipei, policy_data, startup_taipei, youth_bureau
from chromadb_client import add_documents
from llm_enricher import enrich_documents
from pg_client import upsert_resources

logger = logging.getLogger(__name__)

# 所有 spider 及其對應 source 名稱
SPIDERS = [
    {"name": "靜態政策資料", "crawl": policy_data.crawl, "source": "taipei_youth_policy"},
    {"name": "青年局公告", "crawl": youth_bureau.crawl, "source": "taipei_youth_bureau"},
    {"name": "創業台北", "crawl": startup_taipei.crawl, "source": "startup_taipei"},
    {"name": "青年局課程活動", "crawl": class_tcyd.crawl, "source": "taipei_youth_class"},
    {"name": "青年職涯發展平臺", "crawl": career_platform.crawl, "source": "tpyd_career"},
    {"name": "Open Taipei", "crawl": open_taipei.crawl, "source": "open_taipei"},
]


def prepare_documents(raw_docs: list[dict], source: str) -> list[dict]:
    """將爬蟲原始資料整理成 RAG 所需格式。"""
    return [
        {
            "id": str(uuid.uuid4()),
            "content": doc.get("content", doc.get("title", "")),
            "source": doc.get("source", source),
            "url": doc.get("url", ""),
        }
        for doc in raw_docs
        if doc.get("content") or doc.get("title")
    ]


def run_ingest():
    """執行完整的資料攝取流程。每個 spider 爬完立刻增強+寫入。"""
    logger.info("開始資料攝取...")

    total_chroma = 0
    total_pg = 0
    for spider in SPIDERS:
        try:
            logger.info("執行爬蟲：%s", spider["name"])
            raw = spider["crawl"]()
            docs = prepare_documents(raw, source=spider["source"])
            logger.info("  → %s 取得 %d 筆", spider["name"], len(docs))
            if not docs:
                continue
            docs = enrich_documents(docs)
            add_documents(docs)
            pg_count = upsert_resources(docs)
            total_chroma += len(docs)
            total_pg += pg_count
            logger.info("  → %s 寫入完成，ChromaDB %d 筆，PostgreSQL %d 筆", spider["name"], len(docs), pg_count)
        except Exception:
            logger.exception("爬蟲 %s 執行失敗", spider["name"])

    if total_chroma or total_pg:
        logger.info("資料攝取完成，共 ChromaDB %d 筆，PostgreSQL %d 筆", total_chroma, total_pg)
    else:
        logger.warning("本次未取得任何資料")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    run_ingest()
