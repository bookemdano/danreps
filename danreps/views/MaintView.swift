//
//  MaintView.swift
//  danreps
//
//  Created by Daniel Francis on 2/4/25.
//


//
//  DidsView.swift
//  MacLab
//
//  Created by Daniel Francis on 1/8/25.
//

import SwiftUICore
import SwiftUI

struct MaintView: View {
    let _iop = IOPAws(app: "ToDone")
    @State private var _exerSet: ExerSet = .GetDefault()
    @State private var _owner: String = IOPAws.GetOwner()
    @State private var _wait: String = "60"
    @State private var _showingAlert = false
    @State private var _deleteItem: String = ""
    var body: some View {
        NavigationStack{
            List{
                ForEach(_exerSet.ExerItems, id: \.self){ item in
                    NavigationLink(destination: ExerItemView(exerItem: item))
                    {
                        Text(item.description())
                    }
                }
            }
            Spacer()
            HStack{
                Text("Wait(secs): ")
                Spacer()
                TextField("Wait(secs)", text: $_wait)
                    .keyboardType(.numberPad)
                    .background(Color.yellow.opacity(0.2))
            }
            HStack{
                Text("Owner: ")
                Spacer()
                TextField("Owner", text: $_owner)
                    .background(Color.yellow.opacity(0.2))
            }
            Button(action: {
                save()
            }){
                Text("Save")
            }
            NavigationLink(destination: ExerItemView(exerItem: ExerItem(Name: "", Notes: "", PerSide: false))) {
                Text("New Item").bold()
            }
        }
        .navigationTitle("Maintenance")
        .refreshable {
            Refresh()
        }
        .onAppear {
            Refresh()
        }
        
    }

    func save()
    {
        if (_owner != IOPAws.GetOwner()) {
            IOPAws.ChangeOwner(owner: _owner)
            Refresh()
        }
        _exerSet.Interval = Int(_wait) ?? 60
        Task{
            await ExerPersist.SaveAsync(_exerSet)
            Refresh()
        }
    }
    
    func Refresh()
    {
        Task{
            _exerSet.Refresh(other: await ExerPersist.Read(), date: Date());
            _wait = String(_exerSet.Interval ?? 60)
        }
    }
}
