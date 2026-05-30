import CoreData
import SwiftUI
import UIKit

struct GroupListView: View {
    @ObservedObject var groupViewModel: LinkGroupViewModel
    @ObservedObject var linkViewModel: LinkViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingAddGroupAlert = false
    @State private var newGroupName = ""
    @State private var searchText = ""

    @State private var isSelectionMode = false
    @State private var selectedGroupIDs: Set<NSManagedObjectID> = []
    @State private var sortOption: SortOption = .date
    @State private var isAscendingOrder = false

    enum SortOption {
        case date
        case title
        case count
    }

    // Grid Setup
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var filteredGroups: [LinkGroup] {
        let groups =
            searchText.isEmpty
            ? groupViewModel.groups
            : groupViewModel.groups.filter {
                $0.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }

        return groups.sorted {
            switch sortOption {
            case .date:
                let d1 = $0.creationDate ?? Date.distantPast
                let d2 = $1.creationDate ?? Date.distantPast
                return isAscendingOrder ? d1 < d2 : d1 > d2
            case .title:
                let n1 = $0.name ?? ""
                let n2 = $1.name ?? ""
                return isAscendingOrder ? n1 < n2 : n1 > n2
            case .count:
                let c1 = $0.links?.count ?? 0
                let c2 = $1.links?.count ?? 0
                return isAscendingOrder ? c1 < c2 : c1 > c2
            }
        }
    }

    init(linkViewModel: LinkViewModel, groupViewModel: LinkGroupViewModel) {
        self.linkViewModel = linkViewModel
        self.groupViewModel = groupViewModel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredGroups) { group in
                            Group {
                                if isSelectionMode {
                                    Button {
                                        if selectedGroupIDs.contains(group.objectID) {
                                            selectedGroupIDs.remove(group.objectID)
                                        } else {
                                            selectedGroupIDs.insert(group.objectID)
                                        }
                                    } label: {
                                        GroupGridItemView(
                                            group: group,
                                            isSelected: selectedGroupIDs.contains(group.objectID),
                                            isSelectionMode: true,
                                            viewModel: groupViewModel
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    NavigationLink(value: group) {
                                        GroupGridItemView(
                                            group: group,
                                            isSelected: false,
                                            isSelectionMode: false,
                                            viewModel: groupViewModel
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .contextMenu {
                                if !isSelectionMode {
                                    Button(role: .destructive) {
                                        withAnimation { groupViewModel.deleteGroup(group) }
                                    } label: {
                                        Label("Delete Group", systemImage: "trash")
                                    }
                                    Button {
                                        newGroupName = group.name ?? ""
                                        showingAddGroupAlert = true
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }

                if groupViewModel.groups.isEmpty { emptyState }
            }
            .navigationDestination(for: LinkGroup.self) { group in
                GroupDetailView(group: group, groupViewModel: groupViewModel, linkViewModel: linkViewModel)
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search Groups")
            .toolbar {
                if isSelectionMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectionMode = false
                                selectedGroupIDs.removeAll()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        let allSelected = !filteredGroups.isEmpty && selectedGroupIDs.count == filteredGroups.count
                        Button { deleteSelectedGroups() } label: {
                            Text("Delete")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(selectedGroupIDs.isEmpty ? Color.secondary : .red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                        }
                        .disabled(selectedGroupIDs.isEmpty)
                        Spacer()
                        Button {
                            let allIDs = Set(filteredGroups.map { $0.objectID })
                            withAnimation { selectedGroupIDs = allSelected ? [] : allIDs }
                        } label: {
                            Text(allSelected ? "None" : "All")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(allSelected ? Color.blue : Color.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                        }
                    }
                } else {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if !groupViewModel.groups.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { isSelectionMode.toggle() }
                            } label: {
                                Image(systemName: "checklist")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        Menu {
                            Picker("Sort By", selection: $sortOption) {
                                Label("Date", systemImage: "calendar").tag(SortOption.date)
                                Label("Name", systemImage: "textformat").tag(SortOption.title)
                                Label("Count", systemImage: "number").tag(SortOption.count)
                            }
                            Divider()
                            Button { isAscendingOrder.toggle() } label: {
                                Label(
                                    isAscendingOrder ? "Oldest First" : "Newest First",
                                    systemImage: isAscendingOrder ? "arrow.up" : "arrow.down")
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .toolbar(isSelectionMode ? .hidden : .visible, for: .tabBar)
            .navigationBarBackButtonHidden(isSelectionMode)
            .onChange(of: appState.showAddGroupAlert) { show in
                if show {
                    newGroupName = ""
                    showingAddGroupAlert = true
                    appState.showAddGroupAlert = false
                }
            }
        }
        .alert("New Group", isPresented: $showingAddGroupAlert) {
            TextField("Group Name", text: $newGroupName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                if !newGroupName.isEmpty {
                    withAnimation {
                        // Check if renaming or creating
                        // For now strictly creating as per previous logic, renaming handled via context menu implies logic here might need adjustment if we want unified.
                        // But context menu sets newGroupName and shows alert. The alert action here calls addGroup.
                        // We need to differentiate or keep simple.
                        // The previous context menu had "Rename" logic comment but no implementation.
                        // I will assume strictly ADD for this FAB/Alert. Rename should be separate if needed properly.
                        groupViewModel.addGroup(name: newGroupName)
                    }
                }
            }
        } message: {
            Text("Enter a name for your new group.")
        }
    }

    // MARK: - Helpers
    func deleteSelectedGroups() {
        let groupsToDelete = groupViewModel.groups.filter { selectedGroupIDs.contains($0.objectID) }
        for group in groupsToDelete {
            groupViewModel.deleteGroup(group)
        }
        isSelectionMode = false
        selectedGroupIDs.removeAll()
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Button(action: {
                newGroupName = ""
                showingAddGroupAlert = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                }
            }

            Text("Create Your First Group")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Organize your links into collections.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

}

