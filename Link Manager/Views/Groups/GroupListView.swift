import CoreData
import SwiftUI
import UIKit

struct GroupListView: View {
    @StateObject private var groupViewModel: LinkGroupViewModel
    @ObservedObject var linkViewModel: LinkViewModel  // Passed to detail view
    @State private var showingAddGroupAlert = false
    @State private var newGroupName = ""
    @State private var selectedGroup: LinkGroup?
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

    init(linkViewModel: LinkViewModel) {
        self.linkViewModel = linkViewModel
        _groupViewModel = StateObject(
            wrappedValue: LinkGroupViewModel(
                context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    searchBar
                        .padding(.horizontal)
                        .padding(.bottom, 16)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredGroups) { group in
                                GroupGridItemView(
                                    group: group,
                                    isSelected: selectedGroupIDs.contains(group.objectID),
                                    isSelectionMode: isSelectionMode,
                                    onSelect: {
                                        if isSelectionMode {
                                            if selectedGroupIDs.contains(group.objectID) {
                                                selectedGroupIDs.remove(group.objectID)
                                            } else {
                                                selectedGroupIDs.insert(group.objectID)
                                            }
                                        } else {
                                            selectedGroup = group
                                        }
                                    },
                                    viewModel: groupViewModel,  // Pass VM for logic
                                    destination: GroupDetailView(
                                        group: group,
                                        groupViewModel: groupViewModel,
                                        linkViewModel: linkViewModel
                                    ),
                                    selectionBinding: $selectedGroup
                                )
                                .contextMenu {
                                    if !isSelectionMode {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                groupViewModel.deleteGroup(group)
                                            }
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
                        .padding(.bottom, isSelectionMode ? 80 : 20)
                    }
                }

                if groupViewModel.groups.isEmpty {
                    emptyState
                }

                // Floating Action Button
                if !isSelectionMode {
                    fabView
                }

                // Bottom Toolbar
                if isSelectionMode {
                    selectionToolbar
                }
            }
            .toolbar(.hidden, for: .navigationBar)  // Hide default navbar
            .toolbar(.visible, for: .tabBar)
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

    // MARK: - Header
    var headerView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Groups")
                        .font(.system(.largeTitle, design: .default))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("Your collections")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Edit/Select Button
                    if !groupViewModel.groups.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectionMode.toggle()
                                if !isSelectionMode { selectedGroupIDs.removeAll() }
                            }
                        }) {
                            Image(
                                systemName: isSelectionMode ? "checkmark.circle.fill" : "checklist"
                            )
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelectionMode ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(
                                isSelectionMode ? Color.blue : Color(UIColor.tertiarySystemFill)
                            )
                            .clipShape(Circle())
                        }
                    }

                    // Sort Button
                    sortMenu
                }
            }
        }
    }

    var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                Label("Date", systemImage: "calendar").tag(SortOption.date)
                Label("Name", systemImage: "textformat").tag(SortOption.title)
                Label("Count", systemImage: "number").tag(SortOption.count)
            }

            Divider()

            Button {
                isAscendingOrder.toggle()
            } label: {
                Label(
                    isAscendingOrder ? "Oldest First" : "Newest First",
                    systemImage: isAscendingOrder ? "arrow.up" : "arrow.down")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(Color(UIColor.tertiarySystemFill))
                .clipShape(Circle())
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

    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .semibold))

            TextField("Search Groups", text: $searchText)
                .font(.system(size: 16))

            if !searchText.isEmpty {
                Button(action: {
                    withAnimation {
                        searchText = ""
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
                            for: nil)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(10)
        .background(Color(uiColor: .tertiarySystemFill))
        .cornerRadius(10)
    }

    // MARK: - Subviews

    @ViewBuilder
    var fabView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    newGroupName = ""
                    showingAddGroupAlert = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    var selectionToolbar: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                // Delete Button
                Button(action: {
                    deleteSelectedGroups()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                        Text("Delete")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        selectedGroupIDs.isEmpty ? Color.gray.opacity(0.3) : Color.red
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedGroupIDs.isEmpty)

                // Select All Button
                Button(action: {
                    let allIDs = Set(filteredGroups.map { $0.objectID })
                    if selectedGroupIDs.count == allIDs.count {
                        selectedGroupIDs.removeAll()
                    } else {
                        selectedGroupIDs = allIDs
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(
                            systemName: selectedGroupIDs.count == filteredGroups.count
                                ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.system(size: 20))
                        Text(
                            selectedGroupIDs.count == filteredGroups.count
                                ? "None" : "All"
                        )
                        .font(.caption2)
                        .fontWeight(.bold)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground).opacity(0.95))
            .cornerRadius(24)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .transition(.move(edge: .bottom))
    }
}
