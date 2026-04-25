# 資源推薦路由：以語意查詢 RAG 取得相關政策資源
from fastapi import APIRouter, Query
from pydantic import BaseModel

from ..services import rag

router = APIRouter(prefix="/resources", tags=["resources"])


class ResourceItem(BaseModel):
    content: str
    source: str
    url: str
    tags: str
    title: str


@router.get(
    "",
    response_model=list[ResourceItem],
    summary="語意查詢政策資源",
    description="用自然語言關鍵字進行語意搜尋，回傳最相關的政策或活動資源。\n\n使用方式：query 輸入需求描述，n 可調整回傳筆數（1~20）。",
    response_description="符合語意的資源清單。",
)
async def search_resources(
    query: str = Query(..., description="語意查詢字串"),
    n: int = Query(5, ge=1, le=20, description="回傳數量"),
):
    results = await rag.query_resources(query, n_results=n)
    return results
