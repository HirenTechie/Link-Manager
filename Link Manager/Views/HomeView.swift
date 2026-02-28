import Combine
import CoreData
import Kingfisher
import Lottie
import SwiftUI
import UIKit

struct HomeView: View {
    @StateObject private var viewModel: LinkViewModel
    @StateObject private var groupViewModel: LinkGroupViewModel  // Renamed
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home
        case groups
        case favorites
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
            HomeContentView(viewModel: viewModel, showFavoritesOnly: false)
                .tabItem {
                    Label("Home", systemImage: "link")
                }
                .tag(Tab.home)

            GroupListView(linkViewModel: viewModel)
                .tabItem {
                    Label("Groups", systemImage: "folder.fill")
                }
                .tag(Tab.groups)

            HomeContentView(viewModel: viewModel, showFavoritesOnly: true)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(Tab.favorites)
        }
        .accentColor(.blue)
    }
}

enum Tab {
    case home
    case groups
    case favorites
}

struct HomeContentView: View {
    @ObservedObject var viewModel: LinkViewModel
    var showFavoritesOnly: Bool

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) var scenePhase

    // Group Support
    @StateObject private var groupViewModel = LinkGroupViewModel(
        context: PersistenceController.shared.container.viewContext)
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
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    searchBar
                        .padding(.bottom, 16)

                    categoryListView

                    contentListView
                }

                bottomToolbarView

                floatingActionButtonView

                successOverlay
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.refresh()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
            .onChange(of: viewModel.categories) { categories in
                // If selected category no longer exists, switch to All
                if let selected = selectedCategory, !categories.contains(selected) {
                    withAnimation {
                        selectedCategory = nil
                    }
                }
            }
            .sheet(item: $selectedContent) { content in
                LinkDetailView(content: content, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddLinkSheet) {
                AddLinkView(
                    viewModel: viewModel,
                    onSuccess: {
                        withAnimation {
                            showSuccessAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSuccessAnimation = false
                            }
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
                case .deleteAll:
                    return deleteAllAlert
                case .deleteSingle(let content):
                    return deleteSingleAlert(for: content)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .semibold))

            TextField("Search", text: $searchText)
                .font(.system(size: 16))

            if !searchText.isEmpty {
                Button(action: {
                    withAnimation {
                        searchText = ""
                        // Hide keyboard?
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
        .background(Color(UIColor.tertiarySystemFill))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(showFavoritesOnly ? "Favorites" : "Link Manager")
                        .font(.system(.largeTitle, design: .default))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(showFavoritesOnly ? "Your saved collection" : "Organize your digital life")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Edit/Select Button
                    if !displayedContents.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectionMode.toggle()
                                if !isSelectionMode { selectedLinkIDs.removeAll() }
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

    @ViewBuilder
    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOption) {
                Label("Date", systemImage: "calendar").tag(SortOption.date)
                Label("Title", systemImage: "textformat").tag(SortOption.title)
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
        ScrollView {
            if displayedContents.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 60)

                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)

                        Image(systemName: "link")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.bottom, 10)

                    VStack(spacing: 6) {
                        Text(showFavoritesOnly ? "No Favorites Yet" : "No Links Found")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(
                            showFavoritesOnly
                                ? "Mark items as favorite to see them here."
                                : "Your collection is empty.\nTap + to add a new link."
                        )
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                LazyVStack(spacing: 12) {  // Tighter list spacing
                    ForEach(displayedContents) { content in
                        LinkCardView(
                            content: content,
                            onToggleFavorite: {
                                viewModel.toggleFavorite(content)
                            },
                            onAddToGroup: {
                                if let id = content.id {
                                    // Just add this single link, don't enter full selection mode
                                    selectedLinkIDs = [id]
                                    showingAddToGroupSheet = true
                                }
                            },
                            onDelete: {
                                activeAlert = .deleteSingle(content)
                            },
                            onShare: {
                                shareLink(content)
                            },
                            onTap: {
                                if isSelectionMode {
                                    if let id = content.id {
                                        if selectedLinkIDs.contains(id) {
                                            selectedLinkIDs.remove(id)
                                        } else {
                                            selectedLinkIDs.insert(id)
                                        }
                                    }
                                } else {
                                    selectedContent = content
                                }
                            },
                            isSelectionMode: isSelectionMode,
                            isSelected: content.id != nil && selectedLinkIDs.contains(content.id!)
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, isSelectionMode ? 100 : 20)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }

        .sheet(isPresented: $showingAddToGroupSheet) {
            addToGroupSheet
        }
    }

    @ViewBuilder
    private var bottomToolbarView: some View {
        if isSelectionMode {
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    // Delete Button
                    Button(action: {
                        let linksToDelete = displayedContents.filter { content in
                            if let id = content.id { return selectedLinkIDs.contains(id) }
                            return false
                        }
                        if !linksToDelete.isEmpty {
                            withAnimation {
                                viewModel.deleteLinks(linksToDelete)
                                isSelectionMode = false
                                selectedLinkIDs.removeAll()
                            }
                        }
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
                        .background(selectedLinkIDs.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(selectedLinkIDs.isEmpty)

                    // Add to Group Button
                    Button(action: {
                        showingAddToGroupSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 20))
                            Text("Group")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedLinkIDs.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(selectedLinkIDs.isEmpty)

                    // Select All Button
                    Button(action: {
                        let allIDs = Set(displayedContents.compactMap { $0.id })
                        if selectedLinkIDs.count == allIDs.count {
                            // Deselect All
                            selectedLinkIDs.removeAll()
                        } else {
                            // Select All
                            selectedLinkIDs = allIDs
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(
                                systemName: selectedLinkIDs.count == displayedContents.count
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .font(.system(size: 20))
                            Text(
                                selectedLinkIDs.count == displayedContents.count
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
    }

    @ViewBuilder
    private var floatingActionButtonView: some View {
        if !isSelectionMode && !showFavoritesOnly {  // Only show Add button in Main list
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: pasteFromClipboard) {
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
            .transition(.scale.combined(with: .opacity))
            .zIndex(3)
        }
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

    // Group Picker Sheet (Bottom Sheet)
    @ViewBuilder
    private var addToGroupSheet: some View {
        AddToGroupPickerSheet(
            linkViewModel: viewModel,
            groupViewModel: groupViewModel,
            linksToAdd: displayedContents.filter { content in
                guard let id = content.id else { return false }
                return selectedLinkIDs.contains(id)
            },
            onSuccess: {
                showingAddToGroupSheet = false
                isSelectionMode = false
                selectedLinkIDs.removeAll()
            }
        )
    }

    private func pasteFromClipboard() {
        // Just show the sheet
        showingAddLinkSheet = true
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
