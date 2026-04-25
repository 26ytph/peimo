//
//  AppointmentsView.swift
//  duoduo
//
//  諮商師端 Tab 1：查看預約。每位個案都附 AI 自動生成的破冰摘要。
//

import SwiftUI

struct AppointmentsView: View {
    @Environment(AppState.self) private var appState
    @State private var selected: Appointment?

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(title: "新個案預約",
                                     subtitle: "AI 已替你生成個案破冰摘要")
                        ForEach(appState.appointments) { a in
                            Button { selected = a } label: { row(a) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selected) { AppointmentDetailSheet(appointment: $0) }
        }
    }

    private func row(_ a: Appointment) -> some View {
        HStack(alignment: .top, spacing: 14) {
            AvatarView(name: a.youthName, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(a.youthName).font(.headline)
                        .foregroundStyle(CloudTheme.textPrimary)
                    if a.isNew {
                        Text("NEW")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(CloudTheme.pinkGradientSoft))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(a.requestedAt, style: .relative)
                        .font(.caption2).foregroundStyle(CloudTheme.textMuted)
                }
                Text(a.topic)
                    .font(.subheadline)
                    .foregroundStyle(CloudTheme.textPrimary.opacity(0.85))
                HStack(spacing: 6) {
                    ForEach(a.keywords.prefix(3), id: \.self) { k in
                        Text("#\(k)").font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(CloudTheme.pinkSoft))
                            .foregroundStyle(CloudTheme.pinkInk)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)
    }
}

struct AppointmentDetailSheet: View {
    let appointment: Appointment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            AvatarView(name: appointment.youthName, size: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appointment.youthName).font(.title3.bold())
                                    .foregroundStyle(CloudTheme.textPrimary)
                                Text(appointment.topic)
                                    .font(.subheadline)
                                    .foregroundStyle(CloudTheme.textSecondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("AI 破冰一頁式摘要").font(.headline)
                                Spacer()
                            }
                            .foregroundStyle(CloudTheme.pinkInk)
                            Text(appointment.aiSummary)
                                .font(.subheadline)
                                .foregroundStyle(CloudTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cloudCard()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("關鍵字").font(.subheadline.bold())
                                .foregroundStyle(CloudTheme.textSecondary)
                            HStack(spacing: 6) {
                                ForEach(appointment.keywords, id: \.self) { k in
                                    Text("#\(k)").font(.caption)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Capsule().fill(CloudTheme.pinkSoft))
                                        .foregroundStyle(CloudTheme.pinkInk)
                                }
                            }
                        }

                        HStack {
                            PrimaryButton(title: "接受預約", systemImage: "checkmark") {}
                            PrimaryButton(title: "改期", systemImage: "calendar", filled: false) {}
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("個案詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }.foregroundStyle(CloudTheme.pinkInk)
                }
            }
        }
    }
}

#Preview { AppointmentsView().environment(AppState()) }
