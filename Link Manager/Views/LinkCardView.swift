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
    var onTap: (() -> Void)? = nil  // Added onTap closure
    var isSelectionMode: Bool
    var isSelected: Bool
    var deleteIconName: String = "trash"
    var showAddToGroupButton: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Top Content Wrapper
            Button(action: { onTap?() }) {
                HStack(alignment: .top, spacing: 14) {
                    // Selection Circle
                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .blue : .gray)
                            .font(.title2)
                            .transition(.scale)
                            .padding(.top, 10)
                    }

                    // Thumbnail
                    Group {
                        if let thumbUrl = content.thumbIconUrl, let url = URL(string: thumbUrl) {
                            KFImage(url)
                                .resizable()
                                .placeholder {
                                    ZStack {
                                        Color(UIColor.secondarySystemBackground)
                                        initialPlaceholder
                                    }
                                }
                                .fade(duration: 0.25)
                                .aspectRatio(contentMode: .fill)
                        } else {
                            initialPlaceholder
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )

                    // Text Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(content.title ?? "Unknown Title")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            if let date = content.creationDate {
                                Text(date.formatted(date: .numeric, time: .omitted))
                                    .font(.caption2)
                                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                            }
                        }

                        if let url = content.savedLinkUrl {
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let category = content.category?.name {
                            Text(category.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(16)  // Padding for the top section
                .contentShape(Rectangle())  // Ensure the whole area is tappable
            }
            .buttonStyle(PlainButtonStyle())

            if !isSelectionMode {
                Divider()

                // Smart Action Bar (Clean)
                HStack(spacing: 0) {
                    // Favorite Button
                    Button(action: onToggleFavorite) {
                        Image(systemName: content.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(content.isFavorite ? .red : .secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Share Button
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Add to Group Button
                    if showAddToGroupButton {
                        Button(action: onAddToGroup) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()
                    }

                    // Delete Button
                    Button(action: onDelete) {
                        Image(systemName: deleteIconName)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 4)
                .background(Color.clear)
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }

    private var initialPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Text(String(content.title?.prefix(1) ?? "#"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}
