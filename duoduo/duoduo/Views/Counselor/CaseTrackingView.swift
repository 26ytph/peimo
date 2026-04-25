//
//  CaseTrackingView.swift
//  duoduo
//
//  諮商師端 Tab 2：個案追蹤（標籤過濾 / 推薦資源 / 查看近況）。
//

import SwiftUI

struct CaseTrackingView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTagId: UUID? = nil
    @State private var selectedCase: CounselingCase?

    var filteredCases: [CounselingCase] {
        guard let id = selectedTagId else { return appState.cases }
        return appState.cases.filter { $0.tags.contains(where: { $0.id == id }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: "個案追蹤", subtitle: "可用標籤分類、為個案推薦資源")
                        .padding(.horizontal, 18)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip(title: "全部", isSelected: selectedTagId == nil) {
                                selectedTagId = nil
                            }
                            ForEach(appState.caseTags) { tag in
                                chip(title: tag.name,
                                     isSelected: selectedTagId == tag.id,
                                     color: Color(hex: tag.colorHex)) {
                                    selectedTagId = (selectedTagId == tag.id) ? nil : tag.id
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCases) { c in
                                Button { selectedCase = c } label: { row(c) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                    }
                }
                .padding(.top, 14)
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedCase) { CaseDetailSheet(caseItem: $0) }
        }
    }

    private func chip(title: String, isSelected: Bool,
                      color: Color = CloudTheme.pinkSoft,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(isSelected
                                           ? AnyShapeStyle(CloudTheme.pinkGradientSoft)
                                           : AnyShapeStyle(color.opacity(0.7))))
                .foregroundStyle(isSelected ? .white : CloudTheme.textPrimary)
        }
    }

    private func row(_ c: CounselingCase) -> some View {
        HStack(alignment: .top, spacing: 14) {
            AvatarView(name: c.youthName, size: 48)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(c.youthName).font(.headline)
                        .foregroundStyle(CloudTheme.textPrimary)
                    Spacer()
                    Text(c.lastContact, style: .relative)
                        .font(.caption2).foregroundStyle(CloudTheme.textMuted)
                }
                Text(c.statusNote)
                    .font(.footnote)
                    .foregroundStyle(CloudTheme.textPrimary.opacity(0.8))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    ForEach(c.tags) { t in
                        Text(t.name).font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: t.colorHex).opacity(0.7)))
                            .foregroundStyle(CloudTheme.textPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)
    }
}

// MARK: - 個案詳情 Sheet
struct CaseDetailSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let caseItem: CounselingCase

    @State private var showResourcePicker = false
    @State private var showTagPicker = false

    private var liveCase: CounselingCase {
        appState.cases.first(where: { $0.id == caseItem.id }) ?? caseItem
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            AvatarView(name: liveCase.youthName, size: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(liveCase.youthName).font(.title3.bold())
                                    .foregroundStyle(CloudTheme.textPrimary)
                                Text("最近聯絡：\(liveCase.lastContact, style: .relative) 前")
                                    .font(.footnote)
                                    .foregroundStyle(CloudTheme.textSecondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("分類標籤").font(.headline)
                                    .foregroundStyle(CloudTheme.textPrimary)
                                Spacer()
                                Button { showTagPicker = true } label: {
                                    Label("加標籤", systemImage: "tag.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(CloudTheme.pinkInk)
                                }
                            }
                            HStack(spacing: 6) {
                                ForEach(liveCase.tags) { t in
                                    Text(t.name).font(.caption)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Capsule().fill(Color(hex: t.colorHex).opacity(0.7)))
                                        .foregroundStyle(CloudTheme.textPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cloudCard()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("個案近況").font(.headline)
                                .foregroundStyle(CloudTheme.textPrimary)
                            Text(liveCase.statusNote)
                                .font(.subheadline)
                                .foregroundStyle(CloudTheme.textPrimary.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cloudCard()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("已推薦資源").font(.headline)
                                    .foregroundStyle(CloudTheme.textPrimary)
                                Spacer()
                                Button { showResourcePicker = true } label: {
                                    Label("發送卡片", systemImage: "paperplane.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(CloudTheme.pinkInk)
                                }
                            }
                            ForEach(liveCase.recommendedResourceIds, id: \.self) { rid in
                                if let r = appState.resource(by: rid) {
                                    ResourceCardView(card: r, compact: true)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("個案追蹤")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }.foregroundStyle(CloudTheme.pinkInk)
                }
            }
            .sheet(isPresented: $showResourcePicker) { ResourcePickerSheet(caseItem: liveCase) }
            .sheet(isPresented: $showTagPicker) { TagPickerSheet(caseItem: liveCase) }
        }
    }
}

struct ResourcePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let caseItem: CounselingCase
    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.allResources) { r in
                            Button {
                                appState.recommend(resource: r, to: caseItem)
                                dismiss()
                            } label: { ResourceCardView(card: r, compact: true) }
                                .buttonStyle(.plain)
                        }
                    }.padding(18)
                }
            }
            .navigationTitle("選一張卡片送出")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TagPickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let caseItem: CounselingCase
    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                VStack(spacing: 10) {
                    ForEach(appState.caseTags) { t in
                        Button {
                            appState.addTag(t, to: caseItem); dismiss()
                        } label: {
                            HStack {
                                Circle().fill(Color(hex: t.colorHex)).frame(width: 14, height: 14)
                                Text(t.name).font(.subheadline.bold())
                                    .foregroundStyle(CloudTheme.textPrimary)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(CloudTheme.pinkInk)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                            .shadow(color: CloudTheme.softShadow, radius: 6, y: 2)
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(18)
            }
            .navigationTitle("選擇標籤")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview { CaseTrackingView().environment(AppState()) }
