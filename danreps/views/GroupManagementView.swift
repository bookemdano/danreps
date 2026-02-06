//
//  GroupManagementView.swift
//  danreps
//
//  Created by Daniel Francis on 2/5/26.
//

import SwiftUI

struct GroupManagementView: View {
    @State private var _exerSet: ExerSet = .GetDefault()
    @State private var _newGroup: String = ""
    @State private var _showDeleteConfirmation = false
    @State private var _groupToDelete: String = ""

    var body: some View {
        VStack {
            HStack {
                TextField("New group", text: $_newGroup)
                    .border(Color.gray)
                    .autocapitalization(.words)
                Button("Add") {
                    AddGroup()
                }
                .disabled(_newGroup.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)

            List {
                ForEach(_exerSet.GetGroupsExceptAll(), id: \.self) { group in
                    NavigationLink(destination: GroupExercisesView(group: group, onDone: { Refresh() })) {
                        HStack {
                            Text(group)
                            Spacer()
                            Text("\(ExerciseCount(group))")
                                .foregroundColor(.gray)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            _groupToDelete = group
                            _showDeleteConfirmation = true
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
        }
        .confirmationDialog("Remove group \"\(_groupToDelete)\"?", isPresented: $_showDeleteConfirmation, titleVisibility: .visible) {
            Button("Remove from all exercises", role: .destructive) {
                RemoveGroup(_groupToDelete)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the group from all exercises.")
        }
        .onAppear { Refresh() }
        .refreshable { Refresh() }
        .navigationTitle("Groups")
    }

    func ExerciseCount(_ group: String) -> Int {
        return _exerSet.ExerItems.filter { $0.Groups?.contains(group) == true }.count
    }

    func AddGroup() {
        let name = _newGroup.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return }
        if _exerSet.GetGroupsExceptAll().contains(name) { return }
        // Groups are derived from exercises, so add to first exercise to seed it
        if let firstId = _exerSet.ExerItems.first?.id {
            Task {
                await ExerPersist.ToggleExerciseGroup(exerciseId: firstId, group: name)
                _newGroup = ""
                Refresh()
            }
        }
    }

    func RemoveGroup(_ group: String) {
        Task {
            await ExerPersist.RemoveGroup(group)
            Refresh()
        }
    }

    func Refresh() {
        Task {
            _exerSet.Refresh(other: await ExerPersist.Read(), date: Date())
        }
    }
}

struct GroupExercisesView: View {
    let group: String
    var onDone: () -> Void
    @State private var _exerSet: ExerSet = .GetDefault()

    var body: some View {
        List {
            ForEach(
                _exerSet.ExerItems.sorted {
                    $0.Name.localizedCaseInsensitiveCompare($1.Name) == .orderedAscending
                },
                id: \.id
            ) { item in
                HStack {
                    Text(item.description())
                    Spacer()
                    if item.Groups?.contains(group) == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    ToggleGroup(item.id)
                }
            }
        }
        .onAppear { Refresh() }
        .onDisappear { onDone() }
        .navigationTitle(group)
    }

    func ToggleGroup(_ exerciseId: UUID) {
        Task {
            await ExerPersist.ToggleExerciseGroup(exerciseId: exerciseId, group: group)
            Refresh()
        }
    }

    func Refresh() {
        Task {
            _exerSet.Refresh(other: await ExerPersist.Read(), date: Date())
        }
    }
}
