import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: LinkViewModel
    
    @State private var selectedCategory: Category?
    @State private var showingAddLinkAlert = false
    @State private var newLinkString = ""
    @State private var selectedContent: Content? // For Detail View
    
    init() {
        _viewModel = StateObject(wrappedValue: LinkViewModel(context: PersistenceController.shared.container.viewContext))
    }
    
    var filteredContents: [Content] {
        if let category = selectedCategory {
            return category.contents?.allObjects as? [Content] ?? []
        } else {
            // Show all links if no category selected? Or maybe just recent ones?
            // User requested "at bottom of the category show the all links details", check logic.
            // "Horizontal collection view for the categories... at bottom... show the all links details"
            // Likely implies filtering by category or showing everything if "All" is selected.
            // Let's implement an "All" option implicitly by standard fetch.
            // Ideally we need a FetchRequest for contents.
            return [] // We'll implement a fallback fetch in body
        }
    }
    
    // Using FetchRequest for auto-update
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Content.creationDate, ascending: false)],
        animation: .default)
    private var allContents: FetchedResults<Content>

    var displayedContents: [Content] {
        if let category = selectedCategory {
            return allContents.filter { $0.category == category }
        }
        return Array(allContents)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title
                    HStack {
                        Text("Link Manager")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        
                        // Paste Button
                        Button(action: pasteFromClipboard) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.title2)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // "All" Category
                            Button(action: { selectedCategory = nil }) {
                                VStack {
                                    Circle()
                                        .fill(selectedCategory == nil ? Color.blue : Color.white)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "square.grid.2x2")
                                                .foregroundColor(selectedCategory == nil ? .white : .gray)
                                        )
                                    Text("All")
                                        .font(.caption)
                                        .foregroundColor(selectedCategory == nil ? .blue : .primary)
                                }
                            }
                            
                            ForEach(viewModel.categories) { category in
                                Button(action: { selectedCategory = category }) {
                                    VStack {
                                        // Category Icon (Domain Icon)
                                        if let iconUrl = category.thumbIcon, let url = URL(string: iconUrl) {
                                            AsyncImage(url: url) { phase in
                                                if let image = phase.image {
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } else {
                                                    Color.gray.opacity(0.1)
                                                }
                                            }
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 2))
                                        } else {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Text(String(category.name?.prefix(1) ?? "?"))
                                                        .fontWeight(.bold)
                                                )
                                                .overlay(Circle().stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 2))
                                        }
                                        
                                        Text(category.name ?? "Unknown")
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundColor(selectedCategory == category ? .blue : .primary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    
                    // Links List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(displayedContents) { content in
                                Button(action: { selectedContent = content }) {
                                    LinkCardView(
                                        content: content,
                                        onDelete: {
                                            viewModel.deleteLink(content)
                                        },
                                        onShare: {
                                            shareLink(content)
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedContent) { content in
                LinkDetailView(content: content, viewModel: viewModel)
            }
            .alert("Add Link", isPresented: $showingAddLinkAlert) {
                TextField("URL", text: $newLinkString)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if let url = URL(string: newLinkString) {
                        Task {
                            await viewModel.addLink(url: url)
                        }
                    }
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let string = UIPasteboard.general.string, let url = URL(string: string) {
            newLinkString = string
            showingAddLinkAlert = true
        } else {
            // Show manual entry if clipboard empty
            newLinkString = ""
            showingAddLinkAlert = true
        }
    }
    
    private func shareLink(_ content: Content) {
        guard let urlString = content.savedLinkUrl, let url = URL(string: urlString) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Find top view controller to present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}
