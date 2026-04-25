//
//  CommonComponents.swift
//  duoduo
//
//  通用 UI 元件：主要按鈕、章節標題、輸入框等。
//

import SwiftUI

// MARK: - 主要按鈕（淡粉漸層 / 線框）
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var filled: Bool = true
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                Capsule().fill(filled
                               ? AnyShapeStyle(CloudTheme.pinkGradient)
                               : AnyShapeStyle(Color.white))
            )
            .overlay(
                Capsule().stroke(filled ? Color.clear : CloudTheme.pinkDeep, lineWidth: 1.5)
            )
            .foregroundStyle(filled ? .white : CloudTheme.pinkInk)
            .shadow(color: CloudTheme.softShadow, radius: 8, y: 4)
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - 章節標題
struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(CloudTheme.textPrimary)
            if let s = subtitle {
                Text(s).font(.footnote)
                    .foregroundStyle(CloudTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 軟邊輸入框
struct SoftTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(CloudTheme.textSecondary)
            HStack {
                if let i = icon {
                    Image(systemName: i).foregroundStyle(CloudTheme.pinkDeep)
                }
                TextField(placeholder, text: $text)
                    .foregroundStyle(CloudTheme.textPrimary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(CloudTheme.pinkSoft.opacity(0.6))
            )
        }
    }
}

// MARK: - 簡易雲朵圖示（白色，柔和邊緣）
struct CloudGlyph: View {
    var size: CGFloat = 80

    var body: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: size * 0.6, weight: .regular))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.white, Color(red: 0.96, green: 0.94, blue: 0.98)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: CloudTheme.pinkDeep.opacity(0.18), radius: 8, y: 4)
            .shadow(color: Color.black.opacity(0.06), radius: 3, y: 2)
            .frame(width: size, height: size * 0.75)
    }
}
