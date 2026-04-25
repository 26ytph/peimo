//
//  PathGeneratingView.swift
//  duoduo
//
//  分析動畫：朵朵 AI 正在為你生成職涯路徑。
//

import SwiftUI

struct PathGeneratingView: View {
    @State private var pulse = false
    @State private var stepIndex = 0

    private let steps = [
        "解析你的自我描述…",
        "搜尋政策與職缺資源…",
        "規劃 5 個成長階段…",
        "準備你的職涯雲徑"
    ]

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(CloudTheme.pinkSoft)
                        .frame(width: pulse ? 180 : 140, height: pulse ? 180 : 140)
                        .opacity(0.6)
                    CloudGlyph(size: 120)
                }
                Text("朵朵正在為你織雲")
                    .font(.title2.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                Text(steps[min(stepIndex, steps.count - 1)])
                    .font(.subheadline)
                    .foregroundStyle(CloudTheme.textSecondary)
                    .transition(.opacity)
                    .id(stepIndex)
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            // 文案輪播
            for i in 1..<steps.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.55) {
                    withAnimation { stepIndex = i }
                }
            }
        }
    }
}

#Preview { PathGeneratingView() }
