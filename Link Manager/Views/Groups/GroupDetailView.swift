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
                VStack(spacing: 0) {
                    categoryListView
                        .padding(.vertical, 8)
                    linkListView
                }
            }

            // FAB — bottom left, circle + button
            if !isSelectionMode {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: { showingPasteLinkSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 4)
                        }
                        .padding(.leading, 24)
                        .padding(.bottom, 24)
                        Spacer()
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }
        }
        .navigationTitle(
            isSelectionMode
                ? (selectedLinkIds.isEmpty ? "Select Items" : "\(selectedLinkIds.count) Selected")
                : (group.name ?? "Group")
        )
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText)
        .toolbar {
            if isSelectionMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelectionMode = false
                            selectedLinkIds.removeAll()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    let allSelected = !links.isEmpty && selectedLinkIds.count == links.count

                    Button { deleteSelectedLinks() } label: {
                        Text("Delete")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(selectedLinkIds.isEmpty ? Color.secondary : .red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                    }
                    .disabled(selectedLinkIds.isEmpty)

                    Spacer()

                    Button { showingAddToOtherGroupSheet = true } label: {
                        Text("Move")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(selectedLinkIds.isEmpty ? Color.secondary : .blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                    }
                    .disabled(selectedLinkIds.isEmpty)

                    Spacer()

                    Button {
                        let allIDs = Set(links.map { $0.objectID })
                        withAnimation { selectedLinkIds = allSelected ? [] : allIDs }
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
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { isSelectionMode = true }
                        }) {
                            Image(systemName: "checklist")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }

                        Menu {
                            Picker("Sort By", selection: $sortOption) {
                                Label("Date", systemImage: "calendar").tag(SortOption.dateNewest)
                                Label("Title", systemImage: "textformat").tag(SortOption.titleAZ)
                                Label("Website", systemImage: "globe").tag(SortOption.domain)
                            }
                            Divider()
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
                                    (sortOption == .dateNewest || sortOption == .titleAZ) ? "Ascending" : "Descending",
                                    systemImage: "arrow.up.arrow.down")
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                ToolbarSpacer(placement: .topBarTrailing)

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            newGroupName = group.name ?? ""
                            showingRenameGroupAlert = true
                        }) {
                            Label("Rename Group", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive, action: { showingDeleteGroupConfirmation = true }) {
                            Label("Delete Group", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 26, height: 36)
                          
                            .clipShape(Circle())
                    }
                }
            }
        }

        .toolbar(isSelectionMode ? .hidden : .visible, for: .tabBar)
        .navigationBarBackButtonHidden(isSelectionMode)
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
        List {
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
                    onShare: {},
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
                    onEnterSelectionMode: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelectionMode = true
                            selectedLinkIds.insert(content.objectID)
                        }
                    },
                    isSelectionMode: isSelectionMode,
                    isSelected: isSelectionMode
                        ? selectedLinkIds.contains(content.objectID) : false,
                    showAddToGroupButton: false
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparatorTint(Color.primary.opacity(0.08))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var categoryListView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // "All" pill
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = nil
                        }
                        withAnimation { proxy.scrollTo("all", anchor: .center) }
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
                    .id("all")

                    // Categories from ALL group links (not filtered)
                    let allGroupLinks = group.links?.allObjects as? [Content] ?? []
                    let groupCategoryIDs = Set(allGroupLinks.compactMap { $0.category?.objectID })
                    let distinctCategories = linkViewModel.categories.filter {
                        groupCategoryIDs.contains($0.objectID)
                    }

                    ForEach(distinctCategories) { category in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                            withAnimation { proxy.scrollTo(category.objectID, anchor: .center) }
                        }) {
                            HStack(spacing: 6) {
                                if let iconUrl = category.thumbIcon, let url = URL(string: iconUrl) {
                                    KFImage(url)
                                        .resizable()
                                        .placeholder {
                                            Image(systemName: "globe").font(.system(size: 10))
                                                .foregroundColor(
                                                    selectedCategory == category
                                                        ? Color(UIColor.systemBackground).opacity(0.8)
                                                        : .secondary)
                                        }
                                        .fade(duration: 0.25)
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 16, height: 16)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
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
                        .id(category.objectID)
                    }
                }
                .padding(.horizontal)
            }
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

// MARK: - Preview

#Preview("GroupDetailView") {
    let controller = PersistenceController(inMemory: true)
    let ctx = controller.container.viewContext

    let category = Category(context: ctx)
    category.id = UUID()
    category.name = "YouTube"

    let group = LinkGroup(context: ctx)
    group.id = UUID()
    group.name = "YouTube"
    group.creationDate = Date()

    let mockLinks: [(String, String)] = [
        ("Shadow Studio 9 on Instagram", "https://www.instagram.com/reel/DYkFruwFK"),
        ("Belle Therapy on Instagram", "https://www.instagram.com/reel/DYIclmEhs"),
        ("Free GPT Image 2 & More", "https://www.meigen.ai/?utm_source=sp_auto"),
        ("Same Bedroom But Different", "https://youtube.com/shorts/HwqRIFnjEto"),
        ("Here's how to get a great deal", "https://youtube.com/shorts/xcgtMi9uu-4"),
    ]

    for (title, url) in mockLinks {
        let content = Content(context: ctx)
        content.id = UUID()
        content.title = title
        content.savedLinkUrl = url
        content.creationDate = Date()
        content.domainName = "YouTube"
        content.category = category
        group.addToLinks(content)
    }

    try? ctx.save()

    let linkVM = LinkViewModel(context: ctx)
    let groupVM = LinkGroupViewModel(context: ctx)

    return NavigationStack {
        GroupDetailView(group: group, groupViewModel: groupVM, linkViewModel: linkVM)
    }
    .environment(\.managedObjectContext, ctx)
}
