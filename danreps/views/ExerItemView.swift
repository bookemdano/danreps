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
    @Environment(\.presentationMode) var presentationMode
    @State private var _showDeleteConfirmation = false
    @State var _name: String = ""
    @State var _reps: String = "10"
    @State var _notes: String = ""
    @State var _perSide: Bool = false
    var body: some View {
        VStack
        {
            HStack{
                Text("Name: ")
                TextField("Name", text: $_name)
                    .border(Color.gray)
            }
            HStack{
                Text("Reps: ")
                TextField("Reps", text: $_reps)
                    .keyboardType(.numberPad)
                    .border(Color.gray)
            }
            Text("Notes: ")
            TextEditor(text: $_notes)
                .frame(height: 80)
                .border(Color.gray)
            Toggle("Per Side", isOn: $_perSide)
            Spacer()
            HStack{
                Button(action: {
                    Save()
                }){
                    Text("Save")
                }.padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Button("Delete") {
                    _showDeleteConfirmation = true
                }.padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                .confirmationDialog("Are you sure?", isPresented: $_showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        Delete()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action cannot be undone. Deleting means it never was.")
                }
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }){
                    Text("Cancel")
                }.padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

        }
        .padding(5)
        .onAppear {
            _name = exerItem.Name
            _reps = String(exerItem.Reps)
            _perSide = exerItem.PerSide
            _notes = exerItem.Notes
        }
        .navigationTitle(exerItem.Name)
    }

    
    func Delete()
    {
        Task {
            await ExerPersist.Remove(id: exerItem.id)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func Save()
    {
        Task {
            await ExerPersist.Update(id: exerItem.id, name: _name, reps: Int(_reps) ?? 1, perSide: _perSide, notes: _notes)
            presentationMode.wrappedValue.dismiss()
        }
    }

}
