//
//  ContentView.swift
//  duoduo
//
//  Created by Luis on 2026/4/25.
//

import SwiftUI

/// App 根 View：直接進入流程（從登入頁開始）。
struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView().environment(AppState())
}
