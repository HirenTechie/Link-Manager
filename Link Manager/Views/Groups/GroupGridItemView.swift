import CoreData
import SwiftUI

struct GroupGridItemView<Destination: View>: View {
    @ObservedObject var group: LinkGroup
    let isSelected: Bool
    let isSelectionMode: Bool
    let onSelect: () -> Void
    let viewModel: LinkGroupViewModel
    let destination: Destination
    @Binding var selectionBinding: LinkGroup?

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                GroupCardView(
                    group: group
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .blue : .gray)
                        .background(Circle().fill(Color.white))
                        .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        // Removed .disabled(isSelectionMode) to allow tapping for selection
        .background(
            NavigationLink(
                destination: destination,
                tag: group,
                selection: $selectionBinding
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
}
