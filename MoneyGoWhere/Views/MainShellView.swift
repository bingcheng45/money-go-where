import Observation
import SwiftUI

struct MainShellView: View {
    @Bindable var model: AppModel

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                shellHeader
                Group {
                    switch model.selectedTab {
                    case .chat:
                        ChatView(model: model)
                    case .dashboard:
                        DashboardView(model: model)
                    }
                }
            }

            if model.isSidebarPresented {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture {
                        model.isSidebarPresented = false
                    }

                ChatSidebarView(model: model)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: model.isSidebarPresented)
        .sheet(isPresented: Binding(
            get: { model.editorDraft != nil },
            set: { presented in
                if !presented {
                    model.closeEditor()
                }
            }
        )) {
            RecurringItemEditorView(model: model)
        }
    }

    private var shellHeader: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    model.isSidebarPresented.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                Spacer()
                if model.isReadOnly {
                    Text("Read only")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                }
            }

            Picker("Primary navigation", selection: $model.selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
    }
}

struct ChatSidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("MoneyGoWhere chats")
                    .font(.headline)
                Spacer()
                Button {
                    model.createNewThread()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.session.chatThreads) { thread in
                        Button {
                            model.selectThread(thread)
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(thread.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(thread.updatedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    model.deleteThread(thread)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(model.session.activeThreadID == thread.id ? Color.accentColor.opacity(0.14) : Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(model.session.profile.displayName.isEmpty ? "MoneyGoWhere User" : model.session.profile.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(model.session.profile.email ?? model.session.profile.localeIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
}

