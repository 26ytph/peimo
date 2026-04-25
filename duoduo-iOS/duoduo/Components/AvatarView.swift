//
//  AvatarView.swift
//  duoduo
//
//  可重用的頭像元件：優先顯示照片（avatarImage），否則顯示姓名首字。
//  照片來源可以是 Assets catalog 圖片名稱、或日後擴充為 Base64 / URL。
//

import SwiftUI

struct AvatarView: View {
    let name: String
    var imageName: String?
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let img = imageName, !img.isEmpty, let ui = UIImage(named: img) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(CloudTheme.pinkInk)
            }
        }
        .frame(width: size, height: size)
        .background(Circle().fill(CloudTheme.pinkSoft))
        .clipShape(Circle())
    }

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "?" }
        return String(first)
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(name: "陳雨潔", size: 48)
        AvatarView(name: "林雅婷", size: 72)
        AvatarView(name: "張育誠", imageName: "avatar_sample", size: 90)
    }
}
