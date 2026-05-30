import CoreData
import SwiftUI

struct GroupGridItemView: View {
    @ObservedObject var group: LinkGroup
    let isSelected: Bool
    let isSelectionMode: Bool
    let viewModel: LinkGroupViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GroupCardView(group: group)
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
}
