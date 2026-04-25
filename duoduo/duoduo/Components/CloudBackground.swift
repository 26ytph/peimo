//
//  CloudBackground.swift
//  duoduo
//
//  極簡背景：淡淡天空漸層 + 兩朵幾乎透明的雲，避免雜亂。
//

import SwiftUI

struct CloudBackground: View {
    var body: some View {
        ZStack {
            CloudTheme.skyGradient.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    cloud(size: 220, opacity: 0.55)
                        .position(x: geo.size.width * 0.20,
                                  y: geo.size.height * 0.10)
                    cloud(size: 280, opacity: 0.40)
                        .position(x: geo.size.width * 0.85,
                                  y: geo.size.height * 0.88)
                }
            }
            .ignoresSafeArea()
        }
    }

    private func cloud(size: CGFloat, opacity: Double) -> some View {
        ZStack {
            Circle().frame(width: size * 0.7, height: size * 0.7)
                .offset(x: -size * 0.25, y: size * 0.05)
            Circle().frame(width: size * 0.85, height: size * 0.85)
                .offset(y: -size * 0.05)
            Circle().frame(width: size * 0.65, height: size * 0.65)
                .offset(x: size * 0.28, y: size * 0.05)
        }
        .foregroundStyle(Color.white.opacity(opacity))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
        .overlay(
            ZStack {
                Circle().frame(width: size * 0.7, height: size * 0.7)
                    .offset(x: -size * 0.25, y: size * 0.05)
                Circle().frame(width: size * 0.85, height: size * 0.85)
                    .offset(y: -size * 0.05)
                Circle().frame(width: size * 0.65, height: size * 0.65)
                    .offset(x: size * 0.28, y: size * 0.05)
            }
            .foregroundStyle(.clear)
            .overlay(
                ZStack {
                    Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)
                        .frame(width: size * 0.7, height: size * 0.7)
                        .offset(x: -size * 0.25, y: size * 0.05)
                    Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)
                        .frame(width: size * 0.85, height: size * 0.85)
                        .offset(y: -size * 0.05)
                    Circle().stroke(Color.white.opacity(0.7), lineWidth: 1)
                        .frame(width: size * 0.65, height: size * 0.65)
                        .offset(x: size * 0.28, y: size * 0.05)
                }
            )
        )
        .blur(radius: 4)
    }
}

#Preview {
    CloudBackground()
}
