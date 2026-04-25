# 排程器：用 APScheduler 定期觸發爬蟲 + 資料寫入
import logging
import time

from apscheduler.schedulers.blocking import BlockingScheduler

from ingest import run_ingest

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)
logger = logging.getLogger(__name__)


def job():
    """排程任務：執行爬蟲與資料攝取。"""
    logger.info("排程任務開始執行")
    try:
        run_ingest()
    except Exception:
        logger.exception("排程任務執行失敗")


if __name__ == "__main__":
    # 啟動時立即執行一次
    logger.info("啟動時立即執行首次爬取...")
    job()

    scheduler = BlockingScheduler()
    scheduler.add_job(job, "interval", hours=24, id="crawl_and_ingest")
    logger.info("排程器啟動，每 24 小時執行一次")
    scheduler.start()
