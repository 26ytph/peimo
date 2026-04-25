//
//  CounselorListView.swift
//  duoduo
//
//  民眾端瀏覽諮商師清單，點擊可查看詳情並預約。
//

import SwiftUI

struct CounselorListView: View {
    @Environment(AppState.self) private var appState
    @State private var selected: Counselor?

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(title: "諮商師",
                                     subtitle: "選擇一位適合你的顧問")
                            .padding(.horizontal, 4)

                        ForEach(appState.counselors) { c in
                            Button { selected = c } label: { counselorRow(c) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selected) { c in
                CounselorDetailSheet(counselor: c)
            }
        }
    }

    private func counselorRow(_ c: Counselor) -> some View {
        HStack(spacing: 14) {
            AvatarView(name: c.name, imageName: c.avatarImage, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(c.name).font(.headline)
                        .foregroundStyle(CloudTheme.textPrimary)
                    statusDot(c.status)
                }
                Text(c.title)
                    .font(.caption)
                    .foregroundStyle(CloudTheme.textSecondary)
                HStack(spacing: 6) {
                    ForEach(c.specialties.prefix(3), id: \.self) { s in
                        Text(s)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(CloudTheme.pinkSoft))
                            .foregroundStyle(CloudTheme.pinkInk)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(CloudTheme.textMuted)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)
    }

    private func statusDot(_ s: CounselorStatus) -> some View {
        HStack(spacing: 4) {
            Circle().fill(s.color).frame(width: 8, height: 8)
            Text(s.rawValue)
                .font(.caption2)
                .foregroundStyle(CloudTheme.textMuted)
        }
    }
}

// MARK: - 諮商師詳情 Sheet
struct CounselorDetailSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let counselor: Counselor

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // 頭像 + 基本資訊
                        VStack(spacing: 10) {
                            AvatarView(name: counselor.name,
                                       imageName: counselor.avatarImage,
                                       size: 90)
                            Text(counselor.name)
                                .font(.title2.bold())
                                .foregroundStyle(CloudTheme.textPrimary)
                            Text(counselor.title)
                                .font(.subheadline)
                                .foregroundStyle(CloudTheme.textSecondary)

                            HStack(spacing: 4) {
                                Circle().fill(counselor.status.color)
                                    .frame(width: 10, height: 10)
                                Text(counselor.status.rawValue)
                                    .font(.caption.bold())
                                    .foregroundStyle(counselor.status.color)
                            }
                        }
                        .padding(.top, 24)

                        // 自我介紹
                        VStack(alignment: .leading, spacing: 8) {
                            Text("關於我").font(.headline)
                                .foregroundStyle(CloudTheme.textPrimary)
                            Text(counselor.bio)
                                .font(.subheadline)
                                .foregroundStyle(CloudTheme.textPrimary.opacity(0.85))
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cloudCard()

                        // 專長
                        VStack(alignment: .leading, spacing: 10) {
                            Text("專長領域").font(.headline)
                                .foregroundStyle(CloudTheme.textPrimary)
                            FlowLayout(spacing: 8) {
                                ForEach(counselor.specialties, id: \.self) { s in
                                    Text(s)
                                        .font(.caption)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Capsule().fill(CloudTheme.pinkSoft))
                                        .foregroundStyle(CloudTheme.pinkInk)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cloudCard()

                        // 申請按鈕
                        let isSelected = appState.selectedCounselorId == counselor.id
                        let isAvailable = counselor.status == .available

                        if isSelected {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(appState.counselorMatchStatus.rawValue)
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(CloudTheme.pinkInk)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(
                                Capsule().fill(CloudTheme.pinkSoft)
                            )
                        } else {
                            PrimaryButton(title: isAvailable ? "申請配對" : "目前無法預約",
                                          systemImage: isAvailable ? "paperplane.fill" : "clock",
                                          enabled: isAvailable && appState.selectedCounselorId == nil) {
                                appState.selectCounselor(counselor)
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                        .foregroundStyle(CloudTheme.pinkInk)
                }
            }
        }
    }
}

// MARK: - FlowLayout（自適應換行）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            height += row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            if i < rows.count - 1 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for sub in row {
                let size = sub.sizeThatFits(.unspecified)
                sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(sub)
            x += size.width + spacing
        }
        return rows
    }
}

#Preview { CounselorListView().environment(AppState()) }
