//
//  MockData.swift
//  duoduo
//

import Foundation

enum MockData {

    // MARK: - 資源卡片（5 大分類）
    static let resources: [ResourceCard] = [
        // 職缺 / 實習
        ResourceCard(
            title: "永續品牌行銷實習生", organization: "綠光社會企業",
            category: .jobIntern,
            summary: "週 3 天｜時薪 220 元",
            description: "參與品牌行銷企劃、社群經營與活動執行，培養永續品牌實戰能力。",
            deadline: "2026/05/15", amount: "時薪 220 元", location: "臺北市中山區",
            tags: ["行銷", "永續", "實習"]
        ),
        ResourceCard(
            title: "臺北市政府工讀計畫", organization: "臺北青年職涯發展中心",
            category: .jobIntern,
            summary: "市府單位短期工讀，週 20 小時",
            description: "提供大專青年於市府單位工讀的機會，可累積公部門經驗。",
            deadline: "每季開放申請", amount: "時薪 200 元", location: "臺北市",
            tags: ["工讀", "公部門", "TYS"]
        ),

        // 課程 / 活動
        ResourceCard(
            title: "以戰代訓・資料分析人才培訓", organization: "勞動力發展署",
            category: .course,
            summary: "120 小時實戰課，月補助 1 萬元",
            description: "120 小時實戰課程 + 企業實作專案，結訓後協助媒合就業。",
            deadline: "2026/05/30", amount: "每月 10,000 元", location: "線上 + 臺北",
            tags: ["資料分析", "補助", "培訓"]
        ),
        ResourceCard(
            title: "青年職涯探索工作坊", organization: "臺北市青年局",
            category: .course,
            summary: "免費半日工作坊，含性向測驗",
            description: "透過小組討論與職業心理測驗，協助你找到自己的職涯方向。",
            deadline: "2026/05/18", amount: "免費", location: "臺北市信義區",
            tags: ["性向", "免費", "工作坊"]
        ),

        // 競賽 / 計劃
        ResourceCard(
            title: "2026 青年百億行動計畫", organization: "教育部青年發展署",
            category: .competition,
            summary: "團隊提案最高補助 35 萬元",
            description: "鼓勵青年自主提案並執行行動方案，培養社會參與能力。",
            deadline: "2026/06/10", amount: "最高 350,000 元",
            tags: ["提案", "行動", "百億"]
        ),
        ResourceCard(
            title: "獎金獵人・社會創新黑客松", organization: "獎金獵人 BHuntr",
            category: .competition,
            summary: "首獎 30 萬，48 小時實作",
            description: "聚焦永續、社會創新議題的全國黑客松。",
            deadline: "2026/05/25", amount: "首獎 300,000 元",
            tags: ["黑客松", "社創", "獎金"]
        ),

        // 創業資源
        ResourceCard(
            title: "青年創業及啟動金貸款", organization: "經濟部中小及新創企業署",
            category: .startup,
            summary: "20~45 歲青年，最高 400 萬元",
            description: "為協助青年創業，提供無擔保品最高 200 萬、有擔保品最高 400 萬的低利貸款。",
            deadline: "長期受理", amount: "最高 400 萬元",
            tags: ["貸款", "青年", "啟動金"]
        ),
        ResourceCard(
            title: "創業臺北・共享辦公空間", organization: "臺北市青年局",
            category: .startup,
            summary: "免費入駐 6 個月，含導師輔導",
            description: "提供獨立工位、會議室與每月 2 場創業導師會議。",
            deadline: "2026/06/30", amount: "免費入駐", location: "臺北市信義區",
            tags: ["創業基地", "共享空間", "導師"]
        ),

        // 國外資源
        ResourceCard(
            title: "青年壯遊・國際交流計畫", organization: "教育部青年發展署",
            category: .overseas,
            summary: "海外服務學習補助 10 萬元",
            description: "支持青年至海外進行服務學習與文化交流。",
            deadline: "2026/07/01", amount: "最高 100,000 元",
            tags: ["國際", "服務學習", "補助"]
        ),
        ResourceCard(
            title: "Taipei Goes Global 海外實習", organization: "臺北市青年局",
            category: .overseas,
            summary: "亞洲城市企業實習，全額機票補助",
            description: "媒合青年赴東京、新加坡、首爾等城市實習 2~3 個月。",
            deadline: "2026/05/20", amount: "全額機票 + 生活費補助",
            tags: ["海外實習", "亞洲", "TYS"]
        )
    ]

    // MARK: - 諮商師
    static let counselors: [Counselor] = [
        Counselor(id: UUID(), name: "林雅婷", title: "資深職涯顧問",
                  avatarImage: nil,
                  specialties: ["新鮮人求職", "履歷健診", "面試模擬"],
                  status: .available,
                  bio: "10 年人資與獵頭經驗，擅長協助文組學生跨足數位產業。"),
        Counselor(id: UUID(), name: "張育誠", title: "創業輔導顧問",
                  avatarImage: nil,
                  specialties: ["商業模式", "募資簡報", "政府補助"],
                  status: .inSession,
                  bio: "曾協助 30+ 新創團隊取得超過 1.2 億元政府資源。"),
        Counselor(id: UUID(), name: "陳怡安", title: "心理諮商師",
                  avatarImage: nil,
                  specialties: ["職場適應", "情緒管理", "生涯焦慮"],
                  status: .available,
                  bio: "臨床心理師背景，專注青年職涯焦慮與自我探索議題。"),
        Counselor(id: UUID(), name: "黃柏翰", title: "海外發展顧問",
                  avatarImage: nil,
                  specialties: ["留學規劃", "海外實習", "跨文化適應"],
                  status: .available,
                  bio: "旅居新加坡與東京 8 年，熟悉亞洲各城市就業市場與簽證制度。"),
        Counselor(id: UUID(), name: "吳佳蓉", title: "設計產業顧問",
                  avatarImage: nil,
                  specialties: ["作品集優化", "UI/UX 轉職", "設計思維"],
                  status: .offline,
                  bio: "前 KKBOX 設計主管，擅長協助非設計背景者轉入 UX 領域。"),
        Counselor(id: UUID(), name: "蔡宗翰", title: "技術職涯顧問",
                  avatarImage: nil,
                  specialties: ["軟體工程", "AI/ML 入門", "技術面試"],
                  status: .available,
                  bio: "全端工程師轉職涯顧問，幫助超過 200 位青年進入科技業。")
    ]

    // MARK: - 預約 / 個案
    static func appointments(youthId: UUID = UUID(),
                             youthName: String = "陳雨潔",
                             youthAvatar: String = "陳雨潔") -> [Appointment] {
        [
            Appointment(id: UUID(), youthId: youthId,
                        youthName: youthName, youthAvatar: youthAvatar,
                        requestedAt: Date().addingTimeInterval(-3600),
                        topic: "畢業前想先確認職涯方向",
                        aiSummary: "23 歲、社會學系應屆畢業，對 NGO 與永續品牌有強烈興趣。\n目前最大焦慮：缺乏資料分析與專案管理實戰經驗。\n建議切入點：先以「以戰代訓」累積硬技能，再媒合社創類實習。",
                        keywords: ["應屆畢業", "永續", "技能落差"], isNew: true),
            Appointment(id: UUID(), youthId: UUID(),
                        youthName: "王宥翔", youthAvatar: "🧢",
                        requestedAt: Date().addingTimeInterval(-7200),
                        topic: "想申請青年創業貸款",
                        aiSummary: "27 歲、資工背景轉職餐飲創業。\n手邊 80 萬自有資金，需 250 萬週轉。\n建議：青年創業及啟動金貸款 + 青創基地進駐。",
                        keywords: ["創業", "餐飲", "貸款"], isNew: true),
            Appointment(id: UUID(), youthId: UUID(),
                        youthName: "李宛真", youthAvatar: "🎨",
                        requestedAt: Date().addingTimeInterval(-86400),
                        topic: "轉職到 UI/UX 設計領域",
                        aiSummary: "26 歲、平面設計師欲轉 UX。\n已自學 Figma 半年，缺乏實戰專案。\n建議：以戰代訓 UI/UX 班 + 設計實習媒合。",
                        keywords: ["轉職", "UIUX"], isNew: false)
        ]
    }

    static let caseTags: [CaseTag] = [
        CaseTag(name: "應屆畢業", colorHex: "#FFD9DF"),
        CaseTag(name: "創業準備", colorHex: "#D6E6FF"),
        CaseTag(name: "轉職",     colorHex: "#DCEFD6"),
        CaseTag(name: "需追蹤",   colorHex: "#FFE7C2")
    ]

    static func cases(youthId: UUID, youthName: String, youthAvatar: String) -> [CounselingCase] {
        [
            CounselingCase(id: UUID(), youthId: UUID(),
                           youthName: "王宥翔", youthAvatar: "王宥翔",
                           lastContact: Date().addingTimeInterval(-86400 * 3),
                           tags: [caseTags[1], caseTags[3]],
                           statusNote: "已完成商業模式 Canvas，下週要交貸款計畫書草稿。",
                           recommendedResourceIds: [resources[6].id, resources[7].id]),
            CounselingCase(id: UUID(), youthId: UUID(),
                           youthName: "李宛真", youthAvatar: "李宛真",
                           lastContact: Date().addingTimeInterval(-86400 * 7),
                           tags: [caseTags[2]],
                           statusNote: "已報名 UI/UX 培訓班，等待開課通知。",
                           recommendedResourceIds: [resources[2].id]),
            CounselingCase(id: UUID(), youthId: youthId,
                           youthName: youthName, youthAvatar: youthAvatar,
                           lastContact: Date().addingTimeInterval(-86400 * 1),
                           tags: [caseTags[0], caseTags[3]],
                           statusNote: "對永續品牌很有熱情，需要推資料分析課程。",
                           recommendedResourceIds: [resources[2].id, resources[0].id])
        ]
    }

    // MARK: - AI 訪談題庫
    static let interviewQuestions: [InterviewQuestion] = [
        InterviewQuestion(
            prompt: "用一句話描述你「最想成為的樣子」？",
            hint: "可以是夢想中的職業、影響力，或一種生活方式。",
            quickReplies: ["想創業做永續品牌", "進國際企業歷練", "成為自由工作者"]
        ),
        InterviewQuestion(
            prompt: "比起穩定的工作，你更在意什麼？",
            hint: "沒有對錯，誠實選一個最像你的。",
            quickReplies: ["追求興趣與意義", "高成長與挑戰", "工作與生活平衡"]
        ),
        InterviewQuestion(
            prompt: "你最想在 1 年內補強的能力是什麼？",
            hint: "技術、軟實力都可以。",
            quickReplies: ["資料分析", "簡報表達", "產品設計"]
        ),
        InterviewQuestion(
            prompt: "現在最讓你卡住的事是什麼？",
            hint: "把焦慮說出來，朵朵會幫你拆解。",
            quickReplies: ["不知道方向", "缺實戰經驗", "缺人脈與資源"]
        )
    ]

    // MARK: - 範例個人檔案（demo 預填）
    static let sampleProfile = YouthProfile(
        id: UUID(),
        name: "陳雨潔",
        age: 23,
        school: "國立臺北大學",
        major: "社會學系",
        location: "臺北市大安區",
        avatarImage: nil,
        bio: "喜歡永續議題，希望先在 NGO 累積實務經驗，未來自己創立永續品牌。",
        interests: ["永續設計", "社會企業", "行銷企劃"],
        cvFileName: nil,
        path: nil,
        assignedCounselorId: nil
    )

    /// 假裝 LLM 根據自我敘述生成的職涯路徑
    static func generatePath(for draft: RegistrationDraft, answers: [InterviewAnswer]) -> CareerPath {
        let baseAge = max(draft.age, 18)
        let r = resources
        let stages: [CareerStage] = [
            CareerStage(
                index: 0, title: "認識自己", subtitle: "盤點興趣與價值觀",
                description: "用 2~3 個月時間做職業心理測驗、聊聊自己最在意的事。先別急著選工作。",
                ageRange: "\(baseAge) 歲",
                icon: "sparkles",
                status: .done,
                tasks: [
                    CareerTask(title: "完成性向測驗", done: true),
                    CareerTask(title: "寫一份個人 Mission Statement", done: true)
                ],
                recommendedResourceIds: [r[3].id]
            ),
            CareerStage(
                index: 1, title: "技能盤點", subtitle: "建立技能落差地圖",
                description: "對照你想去的領域所需能力，挑 1~2 個關鍵技能集中補強。",
                ageRange: "\(baseAge)~\(baseAge + 1) 歲",
                icon: "list.bullet.clipboard.fill",
                status: .current,
                tasks: [
                    CareerTask(title: "報名以戰代訓資料分析班", done: false),
                    CareerTask(title: "完成第一個個人 side project", done: false)
                ],
                recommendedResourceIds: [r[2].id]
            ),
            CareerStage(
                index: 2, title: "實戰體驗", subtitle: "累積第一份產業履歷",
                description: "申請實習或政府工讀計畫，把學到的技能放進真實專案中。",
                ageRange: "\(baseAge + 1)~\(baseAge + 2) 歲",
                icon: "graduationcap.fill",
                status: .upcoming,
                tasks: [
                    CareerTask(title: "投遞 3 份實習申請"),
                    CareerTask(title: "參加一次黑客松")
                ],
                recommendedResourceIds: [r[0].id, r[1].id, r[5].id]
            ),
            CareerStage(
                index: 3, title: "正式起飛", subtitle: "媒合首份正職",
                description: "用累積的作品與實習經驗，找到最適合自己的第一份工作。",
                ageRange: "\(baseAge + 2)~\(baseAge + 3) 歲",
                icon: "paperplane.fill",
                status: .upcoming,
                tasks: [
                    CareerTask(title: "預約一次履歷健診"),
                    CareerTask(title: "面試 5 家目標企業")
                ],
                recommendedResourceIds: [r[1].id]
            ),
            CareerStage(
                index: 4, title: "夢想萌芽", subtitle: "醞釀永續品牌雛形",
                description: "工作 1~2 年後，把累積的經驗轉化為自己的事業，從小規模試煉開始。",
                ageRange: "\(baseAge + 3)~\(baseAge + 5) 歲",
                icon: "lightbulb.fill",
                status: .upcoming,
                tasks: [
                    CareerTask(title: "申請青年創業貸款"),
                    CareerTask(title: "進駐青創基地")
                ],
                recommendedResourceIds: [r[6].id, r[7].id, r[4].id]
            )
        ]

        let goal = answers.first?.answer.trimmingCharacters(in: .whitespaces)
        let headline: String = {
            if let g = goal, !g.isEmpty { return g }
            return "屬於你的職涯雲徑"
        }()

        return CareerPath(
            headline: headline,
            summary: "根據你的描述、CV 與訪談，朵朵幫你規劃了 5 個階段的成長路徑，從認識自己一路到夢想萌芽。每個階段都會推薦對應的政策資源。",
            stages: stages,
            generatedAt: Date()
        )
    }
}
