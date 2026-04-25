//
//  RegisterView.swift
//  duoduo
//
//  註冊頁：填寫姓名、年齡、學校、科系，並可上傳 CV（mock 分析）。
//

import SwiftUI

struct RegisterView: View {
    @Environment(AppState.self) private var appState
    @State private var analyzingCV = false

    private var draft: Binding<RegistrationDraft> {
        Binding(get: { appState.registration },
                set: { appState.registration = $0 })
    }

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        SectionTitle(title: "建立你的個人輪廓",
                                     subtitle: "這些資料只用來幫朵朵 AI 推薦最適合的資源")

                        SoftTextField(title: "姓名",
                                      placeholder: "你的名字",
                                      text: draft.name,
                                      icon: "person.fill")

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("年齡").font(.caption)
                                    .foregroundStyle(CloudTheme.textSecondary)
                                Stepper(value: draft.age, in: 16...45) {
                                    Text("\(appState.registration.age) 歲")
                                        .foregroundStyle(CloudTheme.textPrimary)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 14)
                                    .fill(CloudTheme.pinkSoft.opacity(0.6)))
                            }
                            SoftTextField(title: "居住地",
                                          placeholder: "臺北市",
                                          text: draft.location,
                                          icon: "mappin")
                        }

                        SoftTextField(title: "學校",
                                      placeholder: "例：國立臺北大學",
                                      text: draft.school,
                                      icon: "graduationcap.fill")
                        SoftTextField(title: "科系 / 領域",
                                      placeholder: "例：社會學系",
                                      text: draft.major,
                                      icon: "book.closed.fill")

                        cvSection
                    }
                    .padding(22)
                }

                PrimaryButton(title: "下一步：和朵朵聊聊",
                              systemImage: "arrow.right",
                              enabled: canContinue) {
                    appState.finishRegistration()
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
            }
        }
    }

    private var canContinue: Bool {
        !appState.registration.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            stepDot(active: true)
            stepDot(active: false)
            stepDot(active: false)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
    }
    private func stepDot(active: Bool) -> some View {
        Capsule()
            .fill(active ? CloudTheme.pinkDeep : CloudTheme.divider)
            .frame(height: 4)
    }

    // MARK: CV 上傳
    private var cvSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("上傳履歷（可選）")
                .font(.caption).foregroundStyle(CloudTheme.textSecondary)
            VStack(spacing: 10) {
                if let name = appState.registration.cvFileName {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(CloudTheme.pinkDeep)
                        Text(name).font(.subheadline)
                            .foregroundStyle(CloudTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if analyzingCV {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CloudTheme.pinkInk)
                        }
                    }
                    if !appState.registration.cvHighlights.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(appState.registration.cvHighlights, id: \.self) { h in
                                Text("#\(h)")
                                    .font(.caption2)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Capsule().fill(CloudTheme.pinkSoft))
                                    .foregroundStyle(CloudTheme.pinkInk)
                            }
                        }
                    }
                } else {
                    Button {
                        mockUploadCV()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.title2)
                                .foregroundStyle(CloudTheme.pinkInk)
                            Text("點此上傳 PDF / Word")
                                .font(.subheadline)
                                .foregroundStyle(CloudTheme.textSecondary)
                            Text("朵朵會自動萃取你的關鍵字")
                                .font(.caption2)
                                .foregroundStyle(CloudTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity, minHeight: 110)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(CloudTheme.pink.opacity(0.45), style: StrokeStyle(lineWidth: 1.2, dash: [5]))
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            )
        }
    }

    /// Demo：假裝上傳一份 CV，並 LLM 自動萃取關鍵字
    private func mockUploadCV() {
        appState.registration.cvFileName = "我的履歷_2026.pdf"
        analyzingCV = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            appState.registration.cvHighlights = ["永續設計", "社群行銷", "簡報設計", "活動企劃"]
            analyzingCV = false
        }
    }
}

#Preview { RegisterView().environment(AppState()) }
