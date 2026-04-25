"""記憶體版的 mock data store。重啟即重置。"""
from __future__ import annotations
from datetime import datetime, timedelta
from uuid import uuid4
from .schemas import (
    YouthProfile, ResourceCard, ResourceCategory,
    Counselor, CounselorStatus, Appointment, CaseTag, CounselingCase,
    ChatMessage, ChatSender,
    ApplicationStatus, CounselorMatchStatus,
)


# 民眾個人檔案 -------------------------------------------------------
youth_profile = YouthProfile(
    name="陳雨潔",
    age=23,
    school="國立臺北大學",
    major="社會學系",
    location="臺北市大安區",
    bio="喜歡永續議題，希望先在 NGO 累積實務經驗，未來自己創立永續品牌。",
    interests=["永續設計", "社會企業", "行銷企劃"],
    avatarImage=None,
    cvFileName=None,
)

# 申請狀態 store
application_statuses: dict[str, ApplicationStatus] = {}   # resource_id_str → status
counselor_match: dict[str, CounselorMatchStatus] = {}     # counselor_id_str → status
selected_counselor_id: str | None = None


# 資源卡片（5 大分類）---------------------------------------------
resources: list[ResourceCard] = [
    # 職缺/實習
    ResourceCard(
        title="永續品牌行銷實習生", organization="綠光社會企業",
        category=ResourceCategory.job_intern,
        summary="週 3 天｜時薪 220 元",
        description="參與品牌行銷企劃、社群經營與活動執行，培養永續品牌實戰能力。",
        deadline="2026/05/15", amount="時薪 220 元", location="臺北市中山區",
        tags=["行銷", "永續", "實習"],
    ),
    ResourceCard(
        title="臺北市政府工讀計畫", organization="臺北青年職涯發展中心",
        category=ResourceCategory.job_intern,
        summary="市府單位短期工讀，週 20 小時",
        description="提供大專青年於市府單位工讀的機會，可累積公部門經驗。",
        deadline="每季開放申請", amount="時薪 200 元", location="臺北市",
        tags=["工讀", "公部門", "TYS"],
    ),
    # 課程/活動
    ResourceCard(
        title="以戰代訓・資料分析人才培訓", organization="勞動力發展署",
        category=ResourceCategory.course,
        summary="120 小時實戰課，月補助 1 萬元",
        description="120 小時實戰課程 + 企業實作專案，結訓後協助媒合就業。",
        deadline="2026/05/30", amount="每月 10,000 元", location="線上 + 臺北",
        tags=["資料分析", "補助", "培訓"],
    ),
    ResourceCard(
        title="青年職涯探索工作坊", organization="臺北市青年局",
        category=ResourceCategory.course,
        summary="免費半日工作坊，含性向測驗",
        description="透過小組討論與職業心理測驗，協助你找到自己的職涯方向。",
        deadline="2026/05/18", amount="免費", location="臺北市信義區",
        tags=["性向", "免費", "工作坊"],
    ),
    # 競賽/計劃
    ResourceCard(
        title="2026 青年百億行動計畫", organization="教育部青年發展署",
        category=ResourceCategory.competition,
        summary="團隊提案最高補助 35 萬元",
        description="鼓勵青年自主提案並執行行動方案，培養社會參與能力。",
        deadline="2026/06/10", amount="最高 350,000 元",
        tags=["提案", "行動", "百億"],
    ),
    ResourceCard(
        title="獎金獵人・社會創新黑客松", organization="獎金獵人 BHuntr",
        category=ResourceCategory.competition,
        summary="首獎 30 萬，48 小時實作",
        description="聚焦永續、社會創新議題的全國黑客松。",
        deadline="2026/05/25", amount="首獎 300,000 元",
        tags=["黑客松", "社創", "獎金"],
    ),
    # 創業資源
    ResourceCard(
        title="青年創業及啟動金貸款", organization="經濟部中小及新創企業署",
        category=ResourceCategory.startup,
        summary="20~45 歲青年，最高 400 萬元",
        description="為協助青年創業，提供無擔保品最高 200 萬、有擔保品最高 400 萬的低利貸款。",
        deadline="長期受理", amount="最高 400 萬元",
        tags=["貸款", "青年", "啟動金"],
    ),
    ResourceCard(
        title="創業臺北・共享辦公空間", organization="臺北市青年局",
        category=ResourceCategory.startup,
        summary="免費入駐 6 個月，含導師輔導",
        description="提供獨立工位、會議室與每月 2 場創業導師會議。",
        deadline="2026/06/30", amount="免費入駐", location="臺北市信義區",
        tags=["創業基地", "共享空間", "導師"],
    ),
    # 國外資源
    ResourceCard(
        title="青年壯遊・國際交流計畫", organization="教育部青年發展署",
        category=ResourceCategory.overseas,
        summary="海外服務學習補助 10 萬元",
        description="支持青年至海外進行服務學習與文化交流。",
        deadline="2026/07/01", amount="最高 100,000 元",
        tags=["國際", "服務學習", "補助"],
    ),
    ResourceCard(
        title="Taipei Goes Global 海外實習", organization="臺北市青年局",
        category=ResourceCategory.overseas,
        summary="亞洲城市企業實習，全額機票補助",
        description="媒合青年赴東京、新加坡、首爾等城市實習 2~3 個月。",
        deadline="2026/05/20", amount="全額機票 + 生活費補助",
        tags=["海外實習", "亞洲", "TYS"],
    ),
]


# 諮商師 -------------------------------------------------------------
counselors: list[Counselor] = [
    Counselor(
        name="林雅婷", title="資深職涯顧問", avatarImage=None,
        specialties=["新鮮人求職", "履歷健診", "面試模擬"],
        status=CounselorStatus.available,
        bio="擁有 10 年人資與獵頭經驗，最擅長協助文組學生跨足數位產業。",
    ),
    Counselor(
        name="張育誠", title="創業輔導顧問", avatarImage=None,
        specialties=["商業模式", "募資簡報", "政府補助"],
        status=CounselorStatus.in_session,
        bio="曾協助 30+ 新創團隊取得超過 1.2 億元政府資源。",
    ),
    Counselor(
        name="陳怡安", title="心理諮商師", avatarImage=None,
        specialties=["職場適應", "情緒管理", "生涯焦慮"],
        status=CounselorStatus.available,
        bio="臨床心理師背景，專注青年職涯焦慮與自我探索議題。",
    ),
    Counselor(
        name="黃柏翰", title="海外發展顧問", avatarImage=None,
        specialties=["留學規劃", "海外實習", "跨文化適應"],
        status=CounselorStatus.available,
        bio="旅居新加坡與東京 8 年，熟悉亞洲各城市就業市場與簽證制度。",
    ),
    Counselor(
        name="吳佳蓉", title="設計產業顧問", avatarImage=None,
        specialties=["作品集優化", "UI/UX 轉職", "設計思維"],
        status=CounselorStatus.offline,
        bio="前 KKBOX 設計主管，擅長協助非設計背景者轉入 UX 領域。",
    ),
    Counselor(
        name="蔡宗翰", title="技術職涯顧問", avatarImage=None,
        specialties=["軟體工程", "AI/ML 入門", "技術面試"],
        status=CounselorStatus.available,
        bio="全端工程師轉職涯顧問，幫助超過 200 位青年進入科技業。",
    ),
]


# 預約 ---------------------------------------------------------------
now = datetime.utcnow()
appointments: list[Appointment] = [
    Appointment(
        youthId=youth_profile.id, youthName=youth_profile.name,
        youthAvatar=youth_profile.name,
        requestedAt=now - timedelta(hours=1),
        topic="畢業前想先確認職涯方向",
        aiSummary=("23 歲、社會學系應屆畢業，對 NGO 與永續品牌有強烈興趣。\n"
                   "目前最大焦慮：缺乏資料分析與專案管理實戰經驗。\n"
                   "建議切入點：先以「以戰代訓」累積硬技能，再媒合社創類實習。"),
        keywords=["應屆畢業", "永續", "技能落差", "NGO"],
        isNew=True,
    ),
    Appointment(
        youthId=uuid4(), youthName="王宥翔", youthAvatar="王宥翔",
        requestedAt=now - timedelta(hours=2),
        topic="想申請青年創業貸款",
        aiSummary=("27 歲、資工背景轉職餐飲創業。\n"
                   "手邊有 80 萬自有資金，需 250 萬週轉。\n"
                   "建議資源：青年創業及啟動金貸款 + 青創基地進駐。"),
        keywords=["創業", "餐飲", "貸款", "資金"],
        isNew=True,
    ),
    Appointment(
        youthId=uuid4(), youthName="李宛真", youthAvatar="李宛真",
        requestedAt=now - timedelta(days=1),
        topic="轉職到 UI/UX 設計領域",
        aiSummary=("26 歲、平面設計師欲轉 UX。\n"
                   "已自學 Figma 半年，缺乏實戰專案。\n"
                   "建議切入點：以戰代訓 UI/UX 班 + 設計實習媒合。"),
        keywords=["轉職", "UIUX", "培訓"],
        isNew=False,
    ),
]


# 個案標籤 -----------------------------------------------------------
case_tags: list[CaseTag] = [
    CaseTag(name="應屆畢業", colorHex="#FFB1C1"),
    CaseTag(name="創業準備", colorHex="#B8D8FF"),
    CaseTag(name="轉職",     colorHex="#C8E6C9"),
    CaseTag(name="需追蹤",   colorHex="#FFD59E"),
]


# 個案 ---------------------------------------------------------------
cases: list[CounselingCase] = [
    CounselingCase(
        youthId=uuid4(), youthName="王宥翔", youthAvatar="王宥翔",
        lastContact=now - timedelta(days=3),
        tags=[case_tags[1], case_tags[3]],
        statusNote="已完成商業模式 Canvas，下週要交貸款計畫書草稿。",
        recommendedResourceIds=[resources[0].id, resources[6].id],
    ),
    CounselingCase(
        youthId=uuid4(), youthName="李宛真", youthAvatar="李宛真",
        lastContact=now - timedelta(days=7),
        tags=[case_tags[2]],
        statusNote="已報名 UI/UX 培訓班，等待開課通知。",
        recommendedResourceIds=[resources[2].id],
    ),
    CounselingCase(
        youthId=youth_profile.id, youthName=youth_profile.name,
        youthAvatar=youth_profile.name,
        lastContact=now - timedelta(days=1),
        tags=[case_tags[0], case_tags[3]],
        statusNote="對永續品牌很有熱情，但缺資料分析能力，需要推資料分析課程。",
        recommendedResourceIds=[resources[2].id, resources[3].id],
    ),
]


# 民眾的滑卡狀態 -----------------------------------------------------
liked_resource_ids: set = set()
passed_resource_ids: set = set()


# 聊天紀錄 -----------------------------------------------------------
ai_messages: list[ChatMessage] = [
    ChatMessage(sender=ChatSender.ai,
                content="嗨～我是朵朵 ☁️，歡迎來到雲端樹洞。今天想聊什麼呢？"),
]
counselor_messages: list[ChatMessage] = [
    ChatMessage(sender=ChatSender.counselor,
                content="雨潔你好，我是雅婷顧問 👋 上次提到永續品牌，這週有新方向嗎？"),
]
