//
//  ResourceCardView.swift
//  duoduo
//
//  資源卡片：compact 用於列表，full 用於 Tinder 滑卡。
//

import SwiftUI

struct ResourceCardView: View {
    let card: ResourceCard
    var compact: Bool = false
    /// 外層已提供背景時設為 true，避免雙層白底
    var bare: Bool = false

    var body: some View {
        if compact {
            compactBody
        } else {
            fullBody
        }
    }

    // MARK: - 滑卡（Full）
    private var fullBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 類別膠囊 + 主辦
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: card.category.icon)
                        .font(.caption2.bold())
                    Text(card.category.rawValue)
                        .font(.caption2.bold())
                }
                .foregroundStyle(card.category.solidColor)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(card.category.tintColor))

                Spacer()

                Text(card.organization)
                    .font(.caption2)
                    .foregroundStyle(CloudTheme.textMuted)
                    .lineLimit(1)
            }

            // 標題
            Text(card.title)
                .font(.title3.bold())
                .foregroundStyle(CloudTheme.textPrimary)
                .lineLimit(3)

            // 摘要
            Text(card.summary)
                .font(.subheadline)
                .foregroundStyle(CloudTheme.textSecondary)
                .lineSpacing(3)

            if !card.description.isEmpty {
                Text(card.description)
                    .font(.footnote)
                    .foregroundStyle(CloudTheme.textSecondary.opacity(0.8))
                    .lineSpacing(2)
                    .lineLimit(3)
            }

            // Meta 資訊（橫排膠囊）
            HStack(spacing: 8) {
                if let d = card.deadline { metaPill(icon: "calendar", text: d) }
                if let a = card.amount   { metaPill(icon: "yensign.circle", text: a) }
            }

            if let l = card.location {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(l)
                        .font(.caption2)
                }
                .foregroundStyle(CloudTheme.textMuted)
            }

            // Tags
            if !card.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(card.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundStyle(card.category.solidColor)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 14, y: 6)
        .shadow(color: CloudTheme.softShadow, radius: 4, y: 2)
    }

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(CloudTheme.textPrimary)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(
            Capsule().fill(CloudTheme.divider.opacity(0.5))
        )
    }

    // MARK: - 列表（Compact）
    private var compactBody: some View {
        HStack(alignment: .center, spacing: 12) {
            // 類別圖標
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.category.tintColor)
                    .frame(width: 42, height: 42)
                Image(systemName: card.category.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(card.category.solidColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                    .lineLimit(1)

                Text(card.summary)
                    .font(.caption)
                    .foregroundStyle(CloudTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(bare ? 0 : 14)
        .if(!bare) { view in
            view
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white)
                )
                .shadow(color: CloudTheme.softShadow, radius: 6, y: 3)
        }
    }
}

// MARK: - 條件修飾器
extension View {
    @ViewBuilder func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

#Preview {
    ZStack {
        CloudBackground()
        VStack(spacing: 14) {
            ResourceCardView(card: MockData.resources[0])
                .frame(maxHeight: 460)
            ResourceCardView(card: MockData.resources[3], compact: true)
        }.padding()
    }
}
