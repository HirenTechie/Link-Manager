import Combine
import CoreData
import Kingfisher
import Lottie
import SwiftUI
import UIKit

class AppState: ObservableObject {
    @Published var showAddLinkInHome = false
    @Published var showAddGroupAlert = false
    @Published var showAddInGroupDetail = false
    @Published var isInGroupDetail = false
}

struct HomeView: View {
    @StateObject private var viewModel: LinkViewModel
    @StateObject private var groupViewModel: LinkGroupViewModel
    @StateObject private var appState = AppState()
    @State private var selectedTab: AppTab = .home
    @State private var previousTab: AppTab = .home

    enum AppTab: Hashable {
        case home, groups, favorites, add
    }

    init() {
        _viewModel = StateObject(
            wrappedValue: LinkViewModel(context: PersistenceController.shared.container.viewContext)
        )
        _groupViewModel = StateObject(
            wrappedValue: LinkGroupViewModel(
                context: PersistenceController.shared.container.viewContext)
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "link", value: AppTab.home) {
                HomeContentView(
                    viewModel: viewModel,
                    groupViewModel: groupViewModel,
                    showFavoritesOnly: false
                )
            }

            Tab("Groups", systemImage: "folder.fill", value: AppTab.groups) {
                GroupListView(linkViewModel: viewModel, groupViewModel: groupViewModel)
            }

            Tab("Favorites", systemImage: "heart.fill", value: AppTab.favorites) {
                HomeContentView(
                    viewModel: viewModel,
                    groupViewModel: groupViewModel,
                    showFavoritesOnly: true
                )
            }

            Tab("", systemImage: "plus", value: AppTab.add, role: .search) {
                EmptyView()
            }
        }
        .tint(.blue)
        .environmentObject(appState)
        .onChange(of: selectedTab) { newVal in
            if newVal == .add {
                switch previousTab {
                case .home:
                    appState.showAddLinkInHome = true
                case .groups:
                    if appState.isInGroupDetail {
                        appState.showAddInGroupDetail = true
                    } else {
                        appState.showAddGroupAlert = true
                    }
                default:
                    break
                }
                selectedTab = previousTab
            } else {
                previousTab = newVal
            }
        }
    }
}

struct HomeContentView: View {
    @ObservedObject var viewModel: LinkViewModel
    @ObservedObject var groupViewModel: LinkGroupViewModel
    var showFavoritesOnly: Bool
    @EnvironmentObject var appState: AppState

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase

    @State private var showingAddToGroupSheet = false

    @State private var selectedCategory: Category?
    @State private var showingAddLinkSheet = false
    @State private var showSuccessAnimation = false
    @State private var newLinkString = ""
    @State private var selectedContent: Content?  // For Detail View
    @State private var isSelectionMode = false
    @State private var selectedLinkIDs: Set<UUID> = []

    // Sort State
    @State private var isAscendingOrder = false  // Default: Newest first
    @State private var sortOption: SortOption = .date

    // Alerts
    @State private var activeAlert: ActiveAlert?
    @State private var searchText = ""

    enum SortOption {
        case date
        case title
    }

    enum ActiveAlert: Identifiable {
        case deleteAll
        case deleteSingle(Content)

        var id: String {
            switch self {
            case .deleteAll: return "deleteAll"
            case .deleteSingle(let content):
                return "deleteSingle-\(content.objectID.uriRepresentation().absoluteString)"
            }
        }
    }

    // Using FetchRequest for auto-update
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Content.creationDate, ascending: false)],
        animation: .default)
    private var allContents: FetchedResults<Content>

    var displayedContents: [Content] {
        let contents: [Content]

        // 1. Filter by Category
        let categoryFiltered: [Content]
        if let category = selectedCategory {
            categoryFiltered = allContents.filter { $0.category == category }
        } else {
            categoryFiltered = Array(allContents)
        }

        // 2. Filter by Favorites (if applicable)
        let favFiltered: [Content]
        if showFavoritesOnly {
            favFiltered = categoryFiltered.filter { $0.isFavorite }
        } else {
            favFiltered = categoryFiltered
        }

        // 3. Search Filter
        let searchFiltered: [Content]
        if searchText.isEmpty {
            searchFiltered = favFiltered
        } else {
            searchFiltered = favFiltered.filter {
                ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
                    || ($0.savedLinkUrl?.localizedCaseInsensitiveContains(searchText) ?? false)
                    || ($0.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // 4. Sort
        return searchFiltered.sorted {
            switch sortOption {
            case .date:
                if let date1 = $0.creationDate, let date2 = $1.creationDate {
                    return isAscendingOrder ? date1 < date2 : date1 > date2
                }
            case .title:
                let t1 = $0.title ?? ""
                let t2 = $1.title ?? ""
                return isAscendingOrder ? t1 < t2 : t1 > t2
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                contentListView
                successOverlay
            }
            .navigationTitle(showFavoritesOnly ? "Favorites" : "Link Manager")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                if isSelectionMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectionMode = false
                                selectedLinkIDs.removeAll()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        let allIDs = Set(displayedContents.compactMap { $0.id })
                        let allSelected = !displayedContents.isEmpty && selectedLinkIDs == allIDs
                        Button {
                            let toDelete = displayedContents.filter { content in
                                content.id.map { selectedLinkIDs.contains($0) } ?? false
                            }
                            guard !toDelete.isEmpty else { return }
                            withAnimation {
                                viewModel.deleteLinks(toDelete)
                                isSelectionMode = false
                                selectedLinkIDs.removeAll()
                            }
                        } label: {
                            Text("Delete")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(selectedLinkIDs.isEmpty ? Color.secondary : .red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                        }
                        .disabled(selectedLinkIDs.isEmpty)
                        Spacer()
                        Button { showingAddToGroupSheet = true } label: {
                            Text("Move")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(selectedLinkIDs.isEmpty ? Color.secondary : .blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                        }
                        .disabled(selectedLinkIDs.isEmpty)
                        Spacer()
                        Button {
                            withAnimation { selectedLinkIDs = allSelected ? [] : allIDs }
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
                        if !displayedContents.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { isSelectionMode = true }
                            } label: {
                                Image(systemName: "checklist")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        Menu {
                            Picker("Sort By", selection: $sortOption) {
                                Label("Date", systemImage: "calendar").tag(SortOption.date)
                                Label("Title", systemImage: "textformat").tag(SortOption.title)
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
            .onAppear { Task { await viewModel.refresh() } }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active { Task { await viewModel.refresh() } }
            }
            .onChange(of: viewModel.categories) { categories in
                if let selected = selectedCategory, !categories.contains(selected) {
                    withAnimation { selectedCategory = nil }
                }
            }
            .onChange(of: appState.showAddLinkInHome) { show in
                if show && !showFavoritesOnly {
                    showingAddLinkSheet = true
                    appState.showAddLinkInHome = false
                }
            }
            .sheet(item: $selectedContent) { content in
                LinkDetailView(content: content, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddLinkSheet) {
                AddLinkView(
                    viewModel: viewModel,
                    onSuccess: {
                        withAnimation { showSuccessAnimation = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSuccessAnimation = false }
                        }
                    })
            }
            .sheet(isPresented: $showingAddToGroupSheet) {
                AddToGroupPickerSheet(
                    linkViewModel: viewModel,
                    groupViewModel: groupViewModel,
                    linksToAdd: displayedContents.filter { content in
                        if let id = content.id { return selectedLinkIDs.contains(id) }
                        return false
                    },
                    onSuccess: {
                        withAnimation {
                            isSelectionMode = false
                            selectedLinkIDs.removeAll()
                        }
                    }
                )
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .deleteAll: return deleteAllAlert
                case .deleteSingle(let content): return deleteSingleAlert(for: content)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var categoryListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {  // Slightly more breathing room
                // "All" Category
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = nil
                    }
                }) {
                    Text("All")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.medium)
                        .padding(.vertical, 10)  // Taller pills
                        .padding(.horizontal, 22)
                        .background(
                            selectedCategory == nil
                                ? Color.primary : Color(UIColor.secondarySystemGroupedBackground)
                        )  // High contrast for active
                        .foregroundStyle(
                            selectedCategory == nil ? Color(UIColor.systemBackground) : .primary
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }

                ForEach(viewModel.categories) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 8) {
                            if let iconUrl = category.thumbIcon, let url = URL(string: iconUrl) {
                                KFImage(url)
                                    .resizable()
                                    .placeholder {
                                        Image(systemName: "globe")
                                            .font(.system(size: 12))
                                            .foregroundColor(
                                                selectedCategory == category
                                                    ? Color(UIColor.systemBackground).opacity(0.8)
                                                    : .secondary)
                                    }
                                    .interpolation(.high)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 18, height: 18)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(
                                            Color.primary.opacity(
                                                selectedCategory == category ? 0.2 : 0.05))  // Subtle bg for icon
                                    Text(String(category.name?.prefix(1) ?? "#").uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .default))
                                        .foregroundColor(
                                            selectedCategory == category
                                                ? Color(UIColor.systemBackground) : .secondary)
                                }
                                .frame(width: 20, height: 20)
                            }

                            Text(category.name ?? "Unknown")
                                .font(.system(.subheadline, design: .default))
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
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
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private var contentListView: some View {
        List {
            if !viewModel.categories.isEmpty {
                categoryListView
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            ForEach(displayedContents) { content in
                LinkCardView(
                    content: content,
                    onToggleFavorite: { viewModel.toggleFavorite(content) },
                    onAddToGroup: {
                        if let id = content.id {
                            selectedLinkIDs = [id]
                            showingAddToGroupSheet = true
                        }
                    },
                    onDelete: { activeAlert = .deleteSingle(content) },
                    onShare: { shareLink(content) },
                    onTap: {
                        if isSelectionMode {
                            if let id = content.id {
                                if selectedLinkIDs.contains(id) { selectedLinkIDs.remove(id) }
                                else { selectedLinkIDs.insert(id) }
                            }
                        } else { selectedContent = content }
                    },
                    onEnterSelectionMode: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelectionMode = true
                            if let id = content.id { selectedLinkIDs.insert(id) }
                        }
                    },
                    isSelectionMode: isSelectionMode,
                    isSelected: content.id.map { selectedLinkIDs.contains($0) } ?? false
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparatorTint(Color.primary.opacity(0.08))
                .alignmentGuide(.listRowSeparatorLeading) { _ in 82 }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .overlay { if displayedContents.isEmpty { emptyStateView } }
        .animation(.none, value: displayedContents.count)
        .refreshable { await viewModel.refresh() }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: 100, height: 100)
                Image(systemName: "link")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary.opacity(0.6))
            }

            VStack(spacing: 6) {
                Text(showFavoritesOnly ? "No Favorites Yet" : "No Links Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(
                    showFavoritesOnly
                        ? "Mark items as favorite to see them here."
                        : "Your collection is empty.\nTap + to add a new link."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var successOverlay: some View {
        if showSuccessAnimation {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack {
                LottieView(animationName: "success", loopMode: .playOnce)
                    .frame(width: 200, height: 200)
            }
            .transition(.opacity)
            .zIndex(10)
        }
    }

    private var deleteAllAlert: Alert {
        // 1. Specific Category Context
        if let category = selectedCategory {
            // Check if we are also in Favorites mode
            if showFavoritesOnly {
                return Alert(
                    title: Text("Delete Favorite Links in \(category.name ?? "Category")?"),
                    message: Text(
                        "Are you sure you want to delete all favorite links in this category? This cannot be undone."
                    ),
                    primaryButton: .destructive(Text("Delete Favorites")) {
                        withAnimation {
                            // Fetch and delete only favorites in this category
                            if let contents = category.contents?.allObjects as? [Content] {
                                let favorites = contents.filter { $0.isFavorite }
                                viewModel.deleteLinks(favorites)
                            }
                            isSelectionMode = false
                            selectedLinkIDs.removeAll()
                        }
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text("Delete \(category.name ?? "Category") Links?"),
                    message: Text(
                        "Are you sure you want to delete all links in this category? This cannot be undone."
                    ),
                    primaryButton: .destructive(Text("Delete All")) {
                        withAnimation {
                            viewModel.deleteLinks(in: category)
                            selectedCategory = nil  // Reset to All
                            isSelectionMode = false
                            selectedLinkIDs.removeAll()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        // 2. Favorites Mode (Global)
        else if showFavoritesOnly {
            return Alert(
                title: Text("Delete All Favorites?"),
                message: Text(
                    "Are you sure you want to delete ALL your favorite links? This cannot be undone."
                ),
                primaryButton: .destructive(Text("Delete Favorites")) {
                    withAnimation {
                        // Filter allContents for favorites
                        let favorites = allContents.filter { $0.isFavorite }
                        viewModel.deleteLinks(favorites)

                        isSelectionMode = false
                        selectedLinkIDs.removeAll()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        // 3. Global Delete All
        else {
            return Alert(
                title: Text("Delete All Links?"),
                message: Text(
                    "Are you sure you want to delete EVERY link in the app? This cannot be undone."),
                primaryButton: .destructive(Text("Delete Everything")) {
                    withAnimation {
                        viewModel.deleteAllLinks()
                        selectedCategory = nil  // Reset to All
                        isSelectionMode = false
                        selectedLinkIDs.removeAll()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func deleteSingleAlert(for content: Content) -> Alert {
        Alert(
            title: Text("Delete Link"),
            message: Text("Are you sure you want to delete this link?"),
            primaryButton: .destructive(Text("Delete")) {
                withAnimation {
                    viewModel.deleteLink(content)
                }
            },
            secondaryButton: .cancel()
        )
    }

    private func shareLink(_ content: Content) {
        guard let urlString = content.savedLinkUrl, let url = URL(string: urlString) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        // Find top view controller to present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}
