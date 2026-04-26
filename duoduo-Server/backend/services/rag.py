# RAG 服務：ChromaDB 向量查詢與文件寫入
import logging
import os

import chromadb
from chromadb.utils.embedding_functions import GoogleGenerativeAiEmbeddingFunction

from ..config import settings

logger = logging.getLogger(__name__)

embedding_fn = GoogleGenerativeAiEmbeddingFunction(
    api_key=settings.GEMINI_API_KEY,
    model_name="models/gemini-embedding-001",
)

client = chromadb.HttpClient(host=settings.CHROMA_HOST, port=settings.CHROMA_PORT)

collection = client.get_or_create_collection(
    name="taipei_resources",
    metadata={"hnsw:space": "cosine"},
    embedding_function=embedding_fn,
)


async def query_resources(query: str, n_results: int = 5) -> list[dict]:
    """查詢與 query 語意最相關的政策片段。"""
    results = collection.query(query_texts=[query], n_results=n_results)

    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]

    import json as _json

    items = []
    for doc, meta in zip(documents, metadatas):
        important_info_raw = meta.get("important_info", "[]")
        try:
            important_info = _json.loads(important_info_raw) if isinstance(important_info_raw, str) else important_info_raw
        except (_json.JSONDecodeError, TypeError):
            important_info = []
        items.append({
            "resource_id": meta.get("resource_id", ""),
            "content": doc,
            "source": meta.get("source", ""),
            "url": meta.get("url", ""),
            "title": meta.get("title", ""),
            "category": meta.get("category", "其他"),
            "tags": meta.get("tags", ""),
            "important_info": important_info,
        })
    return items


async def add_documents(docs: list[dict]) -> None:
    """將文件 embed 後寫入 ChromaDB。每筆 doc 需有 content, source, url 欄位。"""
    if not docs:
        return

    ids = [f"{doc.get('source', 'unknown')}_{i}" for i, doc in enumerate(docs)]
    documents = [doc["content"] for doc in docs]
    metadatas = [{"source": doc.get("source", ""), "url": doc.get("url", "")} for doc in docs]

    collection.upsert(ids=ids, documents=documents, metadatas=metadatas)
    logger.info("已寫入 %d 筆文件到 ChromaDB", len(docs))
