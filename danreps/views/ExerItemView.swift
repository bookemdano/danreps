//
//  ExerItemView.swift
//  danreps
//
//  Created by Daniel Francis on 2/4/25.
//


//
//  DidView.swift
//  MacLab
//
//  Created by Daniel Francis on 1/10/25.
//

import SwiftUICore
import SwiftUI

struct ExerItemView: View {
    let exerItem: ExerItem
    let history: [(Date, String)]?
    @Environment(\.presentationMode) var presentationMode
    @State private var _showDeleteConfirmation = false
    @State var _name: String = ""
    @State var _notes: String = ""
    @State var _groups: String = ""
    @State var _perSide: Bool = false
    @State var _duration: Bool = false
    var onDone: () -> Void

    var body: some View {
        VStack
        {
            HStack{
                Text("Name: ")
                TextField("Name", text: $_name)
                    .border(Color.gray)
            }
            Text("Notes: ")
            TextEditor(text: $_notes)
                .frame(height: 80)
                .border(Color.gray)
            Toggle("Per Side", isOn: $_perSide)
            Toggle("Duration", isOn: $_duration)
            HStack{
                Text("Groups: ")
                TextField("Groups", text: $_groups)
                    .border(Color.gray)
            }
            Spacer()
            if (history != nil) {
                List{
                    ForEach(history!.reversed(), id: \.0) { item in
                        Text("\(item.0.shortDateTime) \(item.1)")
                    }
                }.listStyle(InsetGroupedListStyle())
                Spacer()
            }
            HStack{
     
                Button("🗑️") {
                    _showDeleteConfirmation = true
                }.padding()
                    .cornerRadius(8)
                .confirmationDialog("Are you sure?", isPresented: $_showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        Delete()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action cannot be undone. Deleting means it never was.")
                }
            }

        }
        .padding(5)
        .onAppear {
            _name = exerItem.Name
            _perSide = exerItem.PerSide
            _duration = exerItem.Duration ?? false
            _notes = exerItem.Notes
            _groups = exerItem.GetGroupsString()
            print("ExerItemView onAppear")
        }
        .onDisappear {
            print("ExerItemView onDisappear")
            Save()
            onDone()
        }
        .navigationTitle(exerItem.Name)
    }

    
    func Delete()
    {
        print("ExerItemView Delete()")
        Task {
            await ExerPersist.Remove(id: exerItem.id)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func Save()
    {
        print("ExerItemView Save()")
        Task {
            await ExerPersist.Update(id: exerItem.id, name: _name, perSide: _perSide, duration: _duration, notes: _notes, csvGroups: _groups)
            presentationMode.wrappedValue.dismiss()
        }
    }

}
