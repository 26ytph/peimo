//
//  duoduoApp.swift
//  duoduo
//
//  Created by Luis on 2026/4/25.
//

import SwiftUI

@main
struct duoduoApp: App {
    /// 全域共享狀態，整個 App 都從這裡讀寫資料
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
