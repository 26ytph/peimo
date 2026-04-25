//
//  ResourceSwipeView.swift
//  duoduo
//
//  Tinder 風格資源卡片左右滑動。簡化版：少裝飾、卡片即重點。
//

import SwiftUI

struct ResourceSwipeView: View {
    @Environment(AppState.self) private var appState
    @State private var showLiked = false
    @State private var topOffset: CGSize = .zero
    @State private var topRotation: Double = 0

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 14) {
                header
                Spacer(minLength: 0)
                ZStack {
                    if appState.swipeQueue.isEmpty {
                        emptyState
                    } else {
                        let visible = Array(appState.swipeQueue.prefix(3).enumerated())
                        ForEach(visible.reversed(), id: \.element.id) { idx, card in
                            cardContainer(card: card, indexFromTop: idx)
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                if !appState.swipeQueue.isEmpty { actionButtons }
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 18)
        }
        .sheet(isPresented: $showLiked) { LikedResourcesView() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("資源探索").font(.title2.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                Text("左滑跳過、右滑收藏")
                    .font(.caption).foregroundStyle(CloudTheme.textSecondary)
            }
            Spacer()
            Button { showLiked = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                    Text("\(appState.likedResources.count)").fontWeight(.semibold)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(Color.white))
                .foregroundStyle(CloudTheme.pinkInk)
                .shadow(color: CloudTheme.softShadow, radius: 6, y: 3)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func cardContainer(card: ResourceCard, indexFromTop idx: Int) -> some View {
        let isTop = (idx == 0)
        let scale = 1.0 - CGFloat(idx) * 0.05
        let yOff  = CGFloat(idx) * 18

        ResourceCardView(card: card)
            .frame(maxHeight: 460)
            .scaleEffect(scale)
            .offset(y: yOff)
            .offset(isTop ? topOffset : .zero)
            .rotationEffect(.degrees(isTop ? topRotation : 0))
            .overlay(alignment: .topLeading) {
                if isTop && topOffset.width > 40 {
                    badge("LIKE", color: CloudTheme.pinkInk, rotation: -12).padding(20)
                } else if isTop && topOffset.width < -40 {
                    badge("PASS", color: CloudTheme.textSecondary, rotation: 12)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .gesture(isTop ? dragGesture(card: card) : nil)
            .animation(.spring(response: 0.35, dampingFraction: 0.78), value: topOffset)
    }

    private func badge(_ t: String, color: Color, rotation: Double) -> some View {
        Text(t)
            .font(.title3.bold())
            .kerning(2)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 3)
            )
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
            .shadow(color: color.opacity(0.25), radius: 6, y: 2)
    }

    private func dragGesture(card: ResourceCard) -> some Gesture {
        DragGesture()
            .onChanged { v in
                topOffset = v.translation
                topRotation = Double(v.translation.width / 18)
            }
            .onEnded { v in
                let threshold: CGFloat = 110
                if v.translation.width > threshold { finish(card: card, direction: .right) }
                else if v.translation.width < -threshold { finish(card: card, direction: .left) }
                else { topOffset = .zero; topRotation = 0 }
            }
    }

    private func finish(card: ResourceCard, direction: SwipeDirection) {
        withAnimation(.easeOut(duration: 0.25)) {
            topOffset = CGSize(width: direction == .right ? 800 : -800, height: 60)
            topRotation = direction == .right ? 25 : -25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            appState.swipe(card: card, direction: direction)
            topOffset = .zero
            topRotation = 0
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 32) {
            roundButton(icon: "xmark", color: CloudTheme.textSecondary) {
                if let top = appState.swipeQueue.first { finish(card: top, direction: .left) }
            }
            roundButton(icon: "heart.fill", color: CloudTheme.pinkInk) {
                if let top = appState.swipeQueue.first { finish(card: top, direction: .right) }
            }
        }
        .padding(.bottom, 8)
    }

    private func roundButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: color.opacity(0.18), radius: 10, y: 4)
                )
                .overlay(Circle().stroke(color.opacity(0.15), lineWidth: 1))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            CloudGlyph(size: 70)
            Text("今天的雲朵都看完囉～").font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)
            Text("可以查看收藏，或重新瀏覽全部資源")
                .font(.footnote).foregroundStyle(CloudTheme.textSecondary)
            HStack(spacing: 10) {
                PrimaryButton(title: "回顧收藏", systemImage: "heart.fill") { showLiked = true }
                PrimaryButton(title: "重新瀏覽", systemImage: "arrow.clockwise", filled: false) {
                    appState.resetSwipeDeck()
                }
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 10, y: 4)
    }
}

struct LikedResourcesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if appState.likedResources.isEmpty {
                            VStack(spacing: 14) {
                                Spacer().frame(height: 60)
                                CloudGlyph(size: 60)
                                Text("還沒有收藏的資源")
                                    .font(.headline)
                                    .foregroundStyle(CloudTheme.textPrimary)
                                Text("在資源探索右滑卡片就能收藏")
                                    .font(.footnote)
                                    .foregroundStyle(CloudTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("\(appState.likedResources.count) 筆收藏")
                                .font(.caption.bold())
                                .foregroundStyle(CloudTheme.textMuted)
                                .padding(.horizontal, 4)

                            ForEach(appState.likedResources) { card in
                                LikedCardRow(card: card)
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("我的收藏")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.foregroundStyle(CloudTheme.pinkInk)
                }
            }
        }
    }
}

// MARK: - 收藏卡片（含申請功能）
struct LikedCardRow: View {
    @Environment(AppState.self) private var appState
    let card: ResourceCard

    private var status: ApplicationStatus {
        appState.applicationStatuses[card.id] ?? .none
    }

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                ResourceCardView(card: card, compact: true, bare: true)

                if status == .none {
                    Button {
                        appState.applyResource(card.id)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                            Text("申請報名")
                        }
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(
                            Capsule().fill(card.category.solidColor)
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white)
            )
            .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)

            // 申請中覆蓋層
            if status == .applying {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(CloudTheme.pinkInk)
                    Text("申請中")
                        .font(.headline.bold())
                        .foregroundStyle(CloudTheme.textPrimary)
                }
            }

            // 報名成功覆蓋層
            if status == .accepted {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.85))
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color(red: 0.50, green: 0.72, blue: 0.50))
                    Text("報名成功")
                        .font(.headline.bold())
                        .foregroundStyle(CloudTheme.textPrimary)
                }
            }
        }
    }
}

#Preview { ResourceSwipeView().environment(AppState()) }
