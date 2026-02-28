import Kingfisher
import SwiftUI

struct AddLinksToGroupSheet: View {
    @ObservedObject var group: LinkGroup
    @ObservedObject var linkViewModel: LinkViewModel
    @ObservedObject var groupViewModel: LinkGroupViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedLinks: Set<Content> = []
    @State private var searchText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Content.creationDate, ascending: false)],
        animation: .default)
    private var allContents: FetchedResults<Content>

    @State private var selectedCategory: Category? = nil

    var availableLinks: [Content] {
        let existingLinks = group.links?.allObjects as? [Content] ?? []
        let existingIDs = Set(existingLinks.compactMap { $0.id })

        return allContents.filter { content in
            guard let id = content.id else { return false }
            return !existingIDs.contains(id)
        }
    }

    var categories: [Category] {
        let cats = Set(availableLinks.compactMap { $0.category })
        return cats.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var filteredLinks: [Content] {
        var links = availableLinks

        // Category Filter
        if let category = selectedCategory {
            links = links.filter { $0.category == category }
        }

        // Search Filter
        if !searchText.isEmpty {
            links = links.filter {
                $0.title?.localizedCaseInsensitiveContains(searchText) == true
                    || $0.savedLinkUrl?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return links
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter Bar
                if !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            ForEach(categories) { category in
                                FilterChip(
                                    title: category.name ?? "Untitled",
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)  // Slightly more padding
                    }
                    .background(Color(uiColor: .systemBackground))  // Match background
                    .padding(.bottom, 4)
                }

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredLinks) { link in
                            VStack(spacing: 0) {
                                HStack(spacing: 16) {
                                    // Checkbox
                                    Image(
                                        systemName: selectedLinks.contains(link)
                                            ? "checkmark.circle.fill" : "circle"
                                    )
                                    .foregroundColor(selectedLinks.contains(link) ? .blue : .gray)
                                    .font(.system(size: 22))

                                    // Thumbnail
                                    if let thumbUrl = link.thumbIconUrl,
                                        let url = URL(string: thumbUrl)
                                    {
                                        KFImage(url)
                                            .resizable()
                                            .placeholder {
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            }
                                            .fade(duration: 0.25)
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8).stroke(
                                                    Color.gray.opacity(0.1), lineWidth: 1)
                                            )
                                    } else {
                                        Image(systemName: "link")
                                            .font(.system(size: 20))
                                            .frame(width: 48, height: 48)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(link.title ?? "Untitled")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(link.savedLinkUrl ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedLinks.contains(link) {
                                        selectedLinks.remove(link)
                                    } else {
                                        selectedLinks.insert(link)
                                    }
                                }

                                Divider()
                                    .padding(.leading, 64)  // Indented divider
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))  // Overall background
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Add Links")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add \(selectedLinks.isEmpty ? "" : "(\(selectedLinks.count))")") {
                        groupViewModel.addLinksToGroup(group: group, links: Array(selectedLinks))
                        dismiss()
                    }
                    .disabled(selectedLinks.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// Helper View for Capsule Chips
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
