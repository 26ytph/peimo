# PostgreSQL 客戶端：將爬蟲結果同步寫入 resources 表
import json
import logging
import os
import uuid

import psycopg2
from psycopg2.extras import execute_values

logger = logging.getLogger(__name__)

DATABASE_URL = os.getenv("DATABASE_URL", "")


def _get_conn():
    if not DATABASE_URL:
        raise RuntimeError("DATABASE_URL not set")
    # psycopg2 用的是同步 postgresql:// scheme
    dsn = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    return psycopg2.connect(dsn)


def upsert_resources(docs: list[dict]) -> int:
    """將文件寫入 PostgreSQL resources 表。回傳寫入筆數。

    每筆 doc 需有 title, content 欄位，可選 tags, source, url。
    以 (title, source) 為 key 做 upsert，避免重複。
    """
    if not docs:
        return 0

    if not DATABASE_URL:
        logger.warning("DATABASE_URL 未設定，跳過 PostgreSQL 寫入")
        return 0

    conn = _get_conn()
    try:
        with conn.cursor() as cur:
            values = []
            for doc in docs:
                tags = doc.get("tags")
                if isinstance(tags, str):
                    tags = [t.strip() for t in tags.split(",") if t.strip()]
                values.append((
                    str(uuid.uuid4()),
                    doc.get("title", ""),
                    doc.get("content", ""),
                    json.dumps(tags, ensure_ascii=False) if tags else None,
                    doc.get("source", ""),
                    doc.get("url", ""),
                ))

            execute_values(
                cur,
                """
                INSERT INTO resources (id, title, content, tags, source, url)
                VALUES %s
                ON CONFLICT (title, source) DO UPDATE SET
                    content = EXCLUDED.content,
                    tags = EXCLUDED.tags,
                    url = EXCLUDED.url,
                    updated_at = NOW()
                """,
                values,
                template="(%s::uuid, %s, %s, %s::jsonb, %s, %s)",
            )
            conn.commit()
            count = len(values)
            logger.info("已寫入 %d 筆文件到 PostgreSQL", count)
            return count
    except Exception:
        conn.rollback()
        logger.exception("PostgreSQL 寫入失敗")
        return 0
    finally:
        conn.close()
