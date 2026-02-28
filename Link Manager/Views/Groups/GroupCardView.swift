import CoreData
import Kingfisher
import SwiftUI
import UIKit

struct GroupCardView: View {
    @ObservedObject var group: LinkGroup

    private var recentLinks: [Content] {
        guard let links = group.links?.allObjects as? [Content] else { return [] }
        return links.sorted {
            ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
        }
        .prefix(4)
        .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail Grid
            thumbnailArea
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name ?? "Untitled Group")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(group.links?.count ?? 0) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private var thumbnailArea: some View {
        if recentLinks.isEmpty {
            // Empty State
            ZStack {
                Color(uiColor: .tertiarySystemGroupedBackground)
                Image(systemName: "folder")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        } else {
            // Grid of up to 4 images
            GeometryReader { geometry in
                let size = geometry.size.width / 2
                let spacing: CGFloat = 2

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: spacing),
                        GridItem(.flexible(), spacing: spacing),
                    ], spacing: spacing
                ) {
                    ForEach(0..<4) { index in
                        if index < recentLinks.count {
                            let link = recentLinks[index]
                            let indexForColor = index % 4

                            // Show Image or Fallback
                            if let iconUrl = link.thumbIconUrl, let url = URL(string: iconUrl) {
                                KFImage(url)
                                    .resizable()
                                    .placeholder {
                                        initialPlaceholder(
                                            for: link, size: size, index: indexForColor)
                                    }
                                    .fade(duration: 0.25)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size, height: size)
                                    .clipped()
                            } else {
                                // Fallback to initial if no URL
                                initialPlaceholder(for: link, size: size, index: indexForColor)
                            }
                        } else {
                            // Blank filler
                            Color(uiColor: .tertiarySystemGroupedBackground)
                                .frame(height: size)
                        }
                    }
                }
            }
            .padding(2)  // Inner border
            .background(Color(uiColor: .systemBackground))
        }
    }

    func initialPlaceholder(for link: Content, size: CGFloat, index: Int) -> some View {
        ZStack {
            colorPlaceholder(index: index)
            Text(String(link.title?.prefix(1) ?? "#").uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: size, height: size)
    }

    func colorPlaceholder(index: Int) -> some View {
        let colors: [Color] = [.blue, .purple, .orange, .pink]
        return colors[index % colors.count].opacity(0.3)  // Increased opacity for visibility
    }
}
