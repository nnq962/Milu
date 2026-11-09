import SwiftUI

/// "Lịch sử trò chuyện": every chat with a question, by when it was last spoken in (Hôm nay, Hôm
/// qua, 7 ngày qua, Trước đó), its first question and its time. Tap one to go back to it; swipe
/// it to delete it, asked first (user request 2026-11-09: the chats kept as the AI apps keep them).
struct ChatHistorySheet: View {
    @Environment(AssistantChats.self) private var chats
    @Environment(\.dismiss) private var dismiss
    /// The chat whose "Xoá" was tapped, until the alert is answered.
    @State private var pendingDeletion: Conversation?

    var body: some View {
        NavigationStack {
            Group {
                if chats.history.isEmpty {
                    ScrollView {
                        EmptyStateCard(title: "Chưa có cuộc trò chuyện",
                                       message: "Những câu bạn hỏi Milu sẽ được lưu ở đây.",
                                       picture: IconCatalog.emojiName("✨"))
                            .padding(.horizontal, Spacing.page)
                            .padding(.top, Spacing.l)
                    }
                } else {
                    list
                }
            }
            .pageBackground()
            .foregroundStyle(Palette.label)
            .navigationTitle("Lịch sử trò chuyện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SheetCloseButton() }
            }
            .systemAlert("Xoá cuộc trò chuyện?", isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            )) {
                Button("Huỷ", role: .cancel) {}
                Button("Xoá", role: .destructive) {
                    if let conversation = pendingDeletion {
                        withAnimation { chats.delete(conversation.id) }
                    }
                }
            } message: {
                Text("Không thể hoàn tác.")
            }
        }
        // On the page colour, not a sheet's white: its white rows would vanish on white, as on
        // the main pages (Simulator 2026-11-09).
        .presentationDetents([.large])
        .presentationBackground(Palette.background)
        .scrollIndicators(.hidden, axes: .vertical)
    }

    /// iOS's own list, for its swipe to delete; drawn as the app's cards.
    private var list: some View {
        List {
            ForEach(Self.sections(of: chats.history), id: \.title) { section in
                Section {
                    ForEach(section.chats) { conversation in
                        row(conversation)
                    }
                } header: {
                    Text(section.title)
                        .textRole(.captionStrong)
                        .foregroundStyle(Palette.secondaryLabel)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func row(_ conversation: Conversation) -> some View {
        Button {
            chats.currentID = conversation.id
            dismiss()
        } label: {
            HStack(spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: RowMetrics.lineGap) {
                    Text(conversation.title)
                        .textRole(.body)
                        .foregroundStyle(Palette.label)
                        .lineLimit(1)
                    Text(Self.when(conversation.lastActivity))
                        .textRole(.caption)
                        .foregroundStyle(Palette.secondaryLabel)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if conversation.id == chats.currentID {
                    Image(systemName: "checkmark")
                        .font(.system(size: IconSize.inline, weight: .semibold))
                        .foregroundStyle(Palette.primary)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Palette.surface)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Not `.destructive`: that takes the row away before the alert is answered.
            Button("Xoá") { pendingDeletion = conversation }
                .tint(Palette.negative)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(conversation.id == chats.currentID ? .isSelected : [])
        .accessibilityAction(named: "Xoá") { pendingDeletion = conversation }
    }

    // MARK: - Nhóm theo ngày

    struct DaySection {
        let title: String
        let chats: [Conversation]
    }

    /// Hôm nay, Hôm qua, 7 ngày qua and Trước đó, in that order, leaving out the empty ones.
    static func sections(of chats: [Conversation], now: Date = .now) -> [DaySection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        func bucket(_ date: Date) -> Int {
            if calendar.isDate(date, inSameDayAs: now) { return 0 }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
               calendar.isDate(date, inSameDayAs: yesterday) { return 1 }
            return date >= weekAgo ? 2 : 3
        }
        let titles = ["Hôm nay", "Hôm qua", "7 ngày qua", "Trước đó"]
        let grouped = Dictionary(grouping: chats) { bucket($0.lastActivity) }
        return (0..<titles.count).compactMap { index in
            grouped[index].map { DaySection(title: titles[index], chats: $0) }
        }
    }

    /// "14:30" today, "08/11" this year, "08/11/2025" before.
    static func when(_ date: Date) -> String {
        Calendar.current.isDateInToday(date)
            ? date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(.vietnam))
            : date.shortDay
    }
}
