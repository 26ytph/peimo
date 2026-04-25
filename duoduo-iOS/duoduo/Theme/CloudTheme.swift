//
//  CloudTheme.swift
//  duoduo
//
//  視覺主題：白底為主、淡淡的粉紅作為強調，整體保持輕盈乾淨。
//

import SwiftUI

enum CloudTheme {
    // 底色
    static let bg          = Color(red: 0.99, green: 0.98, blue: 0.99)
    static let surface     = Color.white
    static let divider     = Color(red: 0.94, green: 0.94, blue: 0.96)

    /// 漸層底（極淡的天空粉藍）
    static let skyTop      = Color(red: 0.99, green: 0.99, blue: 1.00)
    static let skyBottom   = Color(red: 1.00, green: 0.97, blue: 0.98)

    // 強調色（更淡的粉）
    static let pink        = Color(red: 1.00, green: 0.83, blue: 0.86)
    static let pinkDeep    = Color(red: 0.96, green: 0.66, blue: 0.74)
    static let pinkSoft    = Color(red: 1.00, green: 0.94, blue: 0.95)
    static let pinkInk     = Color(red: 0.78, green: 0.45, blue: 0.55)

    // 文字
    static let textPrimary   = Color(red: 0.22, green: 0.22, blue: 0.30)
    static let textSecondary = Color(red: 0.50, green: 0.52, blue: 0.60)
    static let textMuted     = Color(red: 0.72, green: 0.74, blue: 0.80)

    // 陰影（柔和）
    static let softShadow = Color(red: 0.78, green: 0.80, blue: 0.92).opacity(0.18)

    static let skyGradient = LinearGradient(
        colors: [skyTop, skyBottom],
        startPoint: .top, endPoint: .bottom)

    static let pinkGradient = LinearGradient(
        colors: [pinkDeep, Color(red: 0.88, green: 0.48, blue: 0.58)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 淡版漸層（用於裝飾、非按鈕）
    static let pinkGradientSoft = LinearGradient(
        colors: [pink, pinkDeep.opacity(0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// 雲朵卡片樣式：乾淨的白卡 + 輕陰影
struct CloudCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(CloudTheme.surface)
            )
            .shadow(color: CloudTheme.softShadow, radius: 12, x: 0, y: 6)
    }
}

extension View {
    func cloudCard(cornerRadius: CGFloat = 24, padding: CGFloat = 20) -> some View {
        modifier(CloudCardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}
