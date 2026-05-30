import CoreData
import Kingfisher
import SwiftUI
import UIKit

struct LinkCardView: View {
    @ObservedObject var content: Content
    var onToggleFavorite: () -> Void
    var onAddToGroup: () -> Void
    var onDelete: () -> Void
    var onShare: () -> Void
    var onTap: (() -> Void)? = nil
    var onEnterSelectionMode: (() -> Void)? = nil
    var isSelectionMode: Bool
    var isSelected: Bool
    var showAddToGroupButton: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                    .transition(.scale.combined(with: .opacity))
            }

            thumbnailView

            contentView

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .contextMenu(menuItems: { contextMenuItems }, preview: { contextMenuPreview })
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isSelectionMode { trailingSwipeActions }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isSelectionMode { leadingSwipeAction }
        }
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        Group {
            if let thumbUrl = content.thumbIconUrl, let url = URL(string: thumbUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder { circlePlaceholder }
                    .fade(duration: 0.2)
                    .aspectRatio(contentMode: .fill)
            } else {
                circlePlaceholder
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
    }

    private var circlePlaceholder: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.15))
            Text(String(content.title?.prefix(1) ?? "#").uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.blue)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(content.title ?? "Unknown Title")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                if let date = content.creationDate {
                    Text(date.formatted(date: .numeric, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize()
                }
            }

            if let url = content.savedLinkUrl {
                Text(url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let category = content.category?.name {
                Text(category.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                onEnterSelectionMode?()
            }
        } label: {
            Label("Select", systemImage: "checkmark.circle")
        }

        Divider()

        Button { onToggleFavorite() } label: {
            Label(
                content.isFavorite ? "Remove Favorite" : "Add to Favorites",
                systemImage: content.isFavorite ? "heart.slash" : "heart"
            )
        }

        Button { onShare() } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        if showAddToGroupButton {
            Button { onAddToGroup() } label: {
                Label("Add to Group", systemImage: "folder.badge.plus")
            }
        }

        Divider()

        Button(role: .destructive) { onDelete() } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Context Menu Preview

    private var contextMenuPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Square thumbnail
            Group {
                if let thumbUrl = content.thumbIconUrl, let url = URL(string: thumbUrl) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            previewPlaceholder
                        }
                        .fade(duration: 0.2)
                        .aspectRatio(contentMode: .fill)
                } else {
                    previewPlaceholder
                }
            }
            .frame(width: 260, height: 160)
            .clipped()

            // Title + subtitle
            VStack(alignment: .leading, spacing: 5) {
                Text(content.title ?? "Unknown Title")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let url = content.savedLinkUrl {
                    Text(url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 260)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var previewPlaceholder: some View {
        ZStack {
            Color.blue.opacity(0.12)
            Text(String(content.title?.prefix(1) ?? "#").uppercased())
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.blue.opacity(0.6))
        }
    }

    // MARK: - Swipe Actions

    @ViewBuilder
    private var trailingSwipeActions: some View {
        Button(role: .destructive) { onDelete() } label: {
            Label("Delete", systemImage: "trash")
        }

        if showAddToGroupButton {
            Button { onAddToGroup() } label: {
                Label("Group", systemImage: "folder.badge.plus")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    private var leadingSwipeAction: some View {
        Button { onToggleFavorite() } label: {
            Label(
                content.isFavorite ? "Unfavorite" : "Favorite",
                systemImage: content.isFavorite ? "heart.slash.fill" : "heart.fill"
            )
        }
        .tint(content.isFavorite ? .gray : .pink)
    }
}
