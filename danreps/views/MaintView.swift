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
    @State private var _showingAlert = false
    @State private var _deleteItem: String = ""
    var body: some View {
        NavigationStack{
            List{
                ForEach(_exerSet.ExerItems, id: \.self){ item in
                    NavigationLink(destination: ExerItemView(exerItem: item))
                    {
                        Text(item.Name)
                    }
                }
            }
            Spacer()
            HStack{
                Text("Owner: ")
                TextField("Owner", text: $_owner)
                    .background(Color.yellow.opacity(0.2))
                Button(action: {
                    changeOwner(_owner)
                }){
                    Text("Change")
                }
            }
            NavigationLink(destination: ExerItemView(exerItem: ExerItem(Name: "", Reps: 10, Notes: "", PerSide: false))) {
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

    func changeOwner(_ owner: String)
    {
        IOPAws.ChangeOwner(owner: owner)
        Refresh()
    }
    
    func Refresh()
    {
        Task{
            _exerSet.Refresh(other: await ExerPersist.Read(), date: Date());
        }
    }
}
