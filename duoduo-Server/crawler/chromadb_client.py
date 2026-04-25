# ChromaDB 客戶端：crawler 獨立的 ChromaDB 連線與寫入邏輯
import logging
import os

import chromadb
from chromadb.utils.embedding_functions import GoogleGenerativeAiEmbeddingFunction

logger = logging.getLogger(__name__)

CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = int(os.getenv("CHROMA_PORT", "8000"))
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

embedding_fn = GoogleGenerativeAiEmbeddingFunction(
    api_key=GEMINI_API_KEY,
    model_name="models/gemini-embedding-001",
) if GEMINI_API_KEY else None

client = chromadb.HttpClient(host=CHROMA_HOST, port=CHROMA_PORT)

# 若舊 collection 的 embedding function 與新的不同，先刪除再重建
try:
    client.delete_collection(name="taipei_resources")
    logger.info("已刪除舊的 taipei_resources collection（embedding 衝突）")
except Exception:
    pass

collection = client.get_or_create_collection(
    name="taipei_resources",
    metadata={"hnsw:space": "cosine"},
    embedding_function=embedding_fn,
)


def add_documents(docs: list[dict]) -> None:
    """將文件寫入 ChromaDB。每筆 doc 需有 content, source, url 欄位。"""
    if not docs:
        return

    ids = [f"{doc.get('source', 'unknown')}_{i}" for i, doc in enumerate(docs)]
    documents = [doc["content"] for doc in docs]
    metadatas = [
        {
            "source": doc.get("source", ""),
            "url": doc.get("url", ""),
            "title": doc.get("title", ""),
            "tags": doc.get("tags", ""),
        }
        for doc in docs
    ]

    collection.upsert(ids=ids, documents=documents, metadatas=metadatas)
    logger.info("已寫入 %d 筆文件到 ChromaDB", len(docs))
