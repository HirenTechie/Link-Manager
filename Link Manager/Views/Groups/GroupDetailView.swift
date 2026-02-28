import CoreData
import Kingfisher
import SwiftUI

struct GroupDetailView: View {
    @ObservedObject var group: LinkGroup
    @ObservedObject var groupViewModel: LinkGroupViewModel
    @ObservedObject var linkViewModel: LinkViewModel

    enum SortOption {
        case dateNewest
        case dateOldest
        case titleAZ
        case titleZA
        case domain
    }

    @State private var showingAddLinksSheet = false
    @State private var showingPasteLinkSheet = false
    @State private var showingAddToOtherGroupSheet = false
    @State private var selectedContent: Content?
    @State private var linkForGroupSelection: Content?

    // Sorting & Selection
    @State private var sortOption: SortOption = .dateNewest
    @State private var isSelectionMode = false
    @State private var selectedLinkIds: Set<NSManagedObjectID> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteGroupConfirmation = false
    @State private var showingRenameGroupAlert = false
    @State private var newGroupName = ""

    // View State
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedCategory: Category?  // For filter

    var links: [Content] {
        let all = group.links?.allObjects as? [Content] ?? []
        // 0. Filter by Category
        let categoryFiltered: [Content]
        if let category = selectedCategory {
            categoryFiltered = all.filter { $0.category == category }
        } else {
            categoryFiltered = all
        }

        // 1. Sort
        let sorted: [Content]
        switch sortOption {
        case .dateNewest:
            sorted = categoryFiltered.sorted {
                ($0.creationDate ?? Date()) > ($1.creationDate ?? Date())
            }
        case .dateOldest:
            sorted = categoryFiltered.sorted {
                ($0.creationDate ?? Date()) < ($1.creationDate ?? Date())
            }
        case .titleAZ:
            sorted = categoryFiltered.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .titleZA:
            sorted = categoryFiltered.sorted { ($0.title ?? "") > ($1.title ?? "") }
        case .domain:
            sorted = categoryFiltered.sorted { ($0.domainName ?? "") < ($1.domainName ?? "") }
        }

        // 2. Search
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter {
                ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
                    || ($0.savedLinkUrl?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            if links.isEmpty {
                emptyState
            } else {
                ScrollView {
                    // Category Filter
                    categoryListView
                        .padding(.vertical, 8)

                    linkListView
                        .padding(.top)
                }
            }

            // Floating Action Button
            // Floating Add Bar (Replaces FAB + Icon)
            if !isSelectionMode {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        // Create New Link Button
                        Button(action: {
                            showingPasteLinkSheet = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 20))
                                Text("New Link")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Divider()
                            .frame(height: 30)
                            .background(Color.primary.opacity(0.2))

                        // Add Existing Links Button
                        Button(action: {
                            showingAddLinksSheet = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "plus.square.on.square")
                                    .font(.system(size: 20))
                                Text("Existing")
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
                    .padding(12)
                    .background(Color(UIColor.systemGroupedBackground).opacity(0.95))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .navigationTitle(group.name ?? "Group")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // Rename/Edit Actions (Only when NOT in selection mode?)
                    // Or keep the old specific actions but style them?
                    // User wants "consitancy". Home View has: [Selection Circle] [Sort Circle].

                    // Group Options (Rename, Add Links, Delete) -> maybe keep as a trailing menu or separate?
                    // HomeView has "Edit/Select" and "Sort". GroupView has more actions.
                    // Let's keep the "Options" menu for Group Actions, but use the Circle style for Select and Sort.

                    Menu {
                        Button(action: {
                            newGroupName = group.name ?? ""
                            showingRenameGroupAlert = true
                        }) {
                            Label("Rename Group", systemImage: "pencil")
                        }

                        Divider()

                        Button(
                            role: .destructive,
                            action: {
                                showingDeleteGroupConfirmation = true
                            }
                        ) {
                            Label("Delete Group", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        //.frame(width: 36, height: 36)
                        //.background(Color(UIColor.tertiarySystemFill))
                        //.clipShape(Circle())
                        // Keeping it simple for standard nav bar item, or make it a circle too?
                    }

                    // Selection Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelectionMode.toggle()
                            if !isSelectionMode { selectedLinkIds.removeAll() }
                        }
                    }) {
                        Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checklist")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelectionMode ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(
                                isSelectionMode ? Color.blue : Color(UIColor.tertiarySystemFill)
                            )
                            .clipShape(Circle())
                    }

                    // Sort Button (HomeView Style)
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            Label("Date", systemImage: "calendar").tag(SortOption.dateNewest)  // Defaulting to newest logic
                            Label("Title", systemImage: "textformat").tag(SortOption.titleAZ)
                            Label("Website", systemImage: "globe").tag(SortOption.domain)
                        }

                        Divider()

                        // Toggle Logic for Sort Order (Simplifying SortOption to just key + boolean would be better, but mapping for now)
                        Button {
                            switch sortOption {
                            case .dateNewest: sortOption = .dateOldest
                            case .dateOldest: sortOption = .dateNewest
                            case .titleAZ: sortOption = .titleZA
                            case .titleZA: sortOption = .titleAZ
                            default: break
                            }
                        } label: {
                            Label(
                                (sortOption == .dateNewest || sortOption == .titleAZ)
                                    ? "Ascending" : "Descending",  // Label logic approx
                                systemImage: "arrow.up.arrow.down")
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
            }
        }

        .toolbarBackground(.hidden, for: .tabBar)  // Try toolbarBackground as well
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode {
                selectionActionBar
            }
        }
        .sheet(isPresented: $showingAddLinksSheet) {
            AddLinksToGroupSheet(
                group: group, linkViewModel: linkViewModel, groupViewModel: groupViewModel)
        }
        .sheet(item: $selectedContent) { content in
            LinkDetailView(content: content, viewModel: linkViewModel)
        }
        .sheet(isPresented: $showingPasteLinkSheet) {
            AddLinkView(
                viewModel: linkViewModel,
                targetGroup: group,
                groupViewModel: groupViewModel
            )
        }
        .sheet(isPresented: $showingAddToOtherGroupSheet) {
            AddToGroupPickerSheet(
                linkViewModel: linkViewModel,
                groupViewModel: groupViewModel,
                linksToAdd: isSelectionMode
                    ? links.filter { selectedLinkIds.contains($0.objectID) }
                    : (linkForGroupSelection != nil ? [linkForGroupSelection!] : []),
                moveFromGroup: group,
                
                onSuccess: {
                    withAnimation {
                        isSelectionMode = false
                        selectedLinkIds.removeAll()
                        linkForGroupSelection = nil
                    }
                }
            )
        }
        .alert("Delete Selected Links?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete from Library", role: .destructive) {
                performDeleteSelectedLinks()
            }
        } message: {
            Text(
                "This will permanently delete the selected links from your library and all groups.")
        }
        .alert("Rename Group", isPresented: $showingRenameGroupAlert) {
            TextField("Group Name", text: $newGroupName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                groupViewModel.renameGroup(group, newName: newGroupName)
            }
        }
        .alert("Delete Group?", isPresented: $showingDeleteGroupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                groupViewModel.deleteGroup(group)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(
                "Are you sure you want to delete this group? The links inside will NOT be deleted from your library."
            )
        }
    }

    @ViewBuilder
    private var linkListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(links) { content in
                LinkCardView(
                    content: content,
                    onToggleFavorite: {
                        linkViewModel.toggleFavorite(content)
                    },
                    onAddToGroup: {
                        linkForGroupSelection = content
                        showingAddToOtherGroupSheet = true
                    },
                    onDelete: {
                        withAnimation {
                            groupViewModel.removeLinksFromGroup(
                                group: group, links: [content])
                        }
                    },
                    onShare: {
                        // Share logic
                    },
                    onTap: {
                        if isSelectionMode {
                            if selectedLinkIds.contains(content.objectID) {
                                selectedLinkIds.remove(content.objectID)
                            } else {
                                selectedLinkIds.insert(content.objectID)
                            }
                        } else {
                            selectedContent = content
                        }
                    },
                    isSelectionMode: isSelectionMode,
                    isSelected: isSelectionMode
                        ? selectedLinkIds.contains(content.objectID) : false,
                    deleteIconName: "trash",
                    showAddToGroupButton: false
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var categoryListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" Category
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = nil
                    }
                }) {
                    Text("All")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedCategory == nil
                                ? Color.primary : Color(UIColor.secondarySystemGroupedBackground)
                        )
                        .foregroundStyle(
                            selectedCategory == nil ? Color(UIColor.systemBackground) : .primary
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }

                // Filter categories to only those presnet in the group
                let groupCategoryIDs = Set(links.compactMap { $0.category?.objectID })
                let distinctCategories = linkViewModel.categories.filter {
                    groupCategoryIDs.contains($0.objectID)
                }

                ForEach(distinctCategories) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            if let iconUrl = category.thumbIcon, let url = URL(string: iconUrl) {
                                KFImage(url)
                                    .resizable()
                                    .placeholder {
                                        // Placeholder for category icon, 'content' is not available here.
                                        // Using a default globe icon as a fallback.
                                        Image(systemName: "globe").font(.system(size: 10))
                                            .foregroundColor(
                                                selectedCategory == category
                                                    ? Color(UIColor.systemBackground).opacity(0.8)
                                                    : .secondary)
                                    }
                                    .fade(duration: 0.25)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 16, height: 16)  // Reverted to original frame size
                                    .clipShape(RoundedRectangle(cornerRadius: 4))  // Adjusted clipShape for 16x16
                            } else {
                                Text(String(category.name?.prefix(1) ?? "#").uppercased())
                                    .font(.caption2.bold())
                                    .foregroundColor(
                                        selectedCategory == category
                                            ? Color(UIColor.systemBackground) : .secondary)
                            }

                            Text(category.name ?? "Unknown")
                                .font(.system(.subheadline, design: .default))
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            selectedCategory == category
                                ? Color.primary : Color(UIColor.secondarySystemGroupedBackground)
                        )
                        .foregroundStyle(
                            selectedCategory == category
                                ? Color(UIColor.systemBackground) : .primary
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Links Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add links to this group to organize them.")
                .font(.subheadline)
                .foregroundColor(.secondary)

        }
    }

    var selectionActionBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                // Delete Button
                Button(action: {
                    deleteSelectedLinks()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                        Text("Delete")  // User said "Trash color red" - making bg red
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedLinkIds.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedLinkIds.isEmpty)

                // Move Button (Instead of "Add to Group" which makes no sense here)
                // User said "Selection to show this type of UI but not add the group".
                // Image showed Middle Button "Group".
                // I will put "Move" here with folder icon, similar to "Group".
                Button(action: {
                    showingAddToOtherGroupSheet = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 20))
                        Text("Move")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedLinkIds.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedLinkIds.isEmpty)

                // Select All Button
                Button(action: {
                    let allIDs = Set(links.compactMap { $0.objectID })
                    if selectedLinkIds.count == allIDs.count {
                        selectedLinkIds.removeAll()
                    } else {
                        selectedLinkIds = allIDs
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(
                            systemName: selectedLinkIds.count == links.count
                                ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.system(size: 20))
                        Text(
                            selectedLinkIds.count == links.count
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
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(2)
    }

    func deleteSelectedLinks() {
        showingDeleteConfirmation = true
    }

    func performDeleteSelectedLinks() {
        let linksToDelete = links.filter { selectedLinkIds.contains($0.objectID) }
        withAnimation {
            linkViewModel.deleteLinks(linksToDelete)
            isSelectionMode = false
            selectedLinkIds.removeAll()
        }
    }

    func removeSelectedLinksFromGroup() {
        let linksToRemove = links.filter { selectedLinkIds.contains($0.objectID) }
        withAnimation {
            groupViewModel.removeLinksFromGroup(group: group, links: linksToRemove)
            isSelectionMode = false
            selectedLinkIds.removeAll()
        }
    }
}
