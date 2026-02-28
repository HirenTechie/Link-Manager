import CoreData
import SwiftUI

struct AddToGroupPickerSheet: View {
    @ObservedObject var linkViewModel: LinkViewModel
    @ObservedObject var groupViewModel: LinkGroupViewModel
    var linksToAdd: [Content]
    var moveFromGroup: LinkGroup? = nil  // Optional: If set, links will be removed from this group
    var onSuccess: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var showingCreateGroup = false
    @State private var newGroupName = ""
    @State private var showingMoveConfirmation = false
    @State private var selectedGroupIDs: Set<NSManagedObjectID> = []

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showingCreateGroup = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Create New Group")
                        }
                    }
                }

                Section("Select Groups") {
                    if groupViewModel.groups.isEmpty {
                        Text("No groups created yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(groupViewModel.groups) { group in
                            HStack {
                                Image(systemName: group.symbol ?? "folder.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                                Text(group.name?.isEmpty == false ? group.name! : "Untitled Group")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(group.links?.count ?? 0)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)

                                if selectedGroupIDs.contains(group.objectID) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedGroupIDs.contains(group.objectID) {
                                    selectedGroupIDs.remove(group.objectID)
                                } else {
                                    selectedGroupIDs.insert(group.objectID)
                                }
                            }
                        }
                    }
                }
            }

            .navigationTitle(moveFromGroup != nil ? "Move to Group" : "Add to Group")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(moveFromGroup != nil ? "Move" : "Add") {
                        if moveFromGroup != nil {
                            showingMoveConfirmation = true
                        } else {
                            addLinksToSelectedGroups()
                        }
                    }
                    .disabled(selectedGroupIDs.isEmpty)
                    .fontWeight(.bold)
                }
            }
            .alert("New Group", isPresented: $showingCreateGroup) {
                TextField("Group Name", text: $newGroupName)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    if !newGroupName.isEmpty {
                        groupViewModel.addGroup(name: newGroupName)
                    }
                }
            }
            .alert("Move Links?", isPresented: $showingMoveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Move", role: .destructive) {  // Destructive because it removes from source
                    addLinksToSelectedGroups()
                }
            } message: {
                if let groupName = moveFromGroup?.name {
                    Text(
                        "This will remove the selected links from '\(groupName)' and add them to the selected groups."
                    )
                } else {
                    Text("This will move the selected links to the new groups.")
                }
            }
        }
        .onAppear {
            groupViewModel.fetchGroups()
        }
    }

    private func addLinksToSelectedGroups() {
        let selectedGroups = groupViewModel.groups.filter { selectedGroupIDs.contains($0.objectID) }

        // Remove from source group if moving
        if let sourceGroup = moveFromGroup {
            groupViewModel.removeLinksFromGroup(group: sourceGroup, links: linksToAdd)
        }

        // Add to new groups
        for group in selectedGroups {
            groupViewModel.addLinksToGroup(group: group, links: linksToAdd)
        }

        // Force refresh explicitly if needed, but ViewModel should handle it
        groupViewModel.fetchGroups()

        onSuccess()
        dismiss()
    }
}
