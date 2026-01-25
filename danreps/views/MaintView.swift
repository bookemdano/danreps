//
//  MaintView.swift
//  danreps
//
//  Created by Daniel Francis on 2/4/25.
//

import SwiftUI
import DanSwiftLib

struct MaintView: View {
    let _iop = IOPAws(app: "ToDone")
    @State private var _welcomed: Bool = (IOPAws.getUserID() != nil)
    @State private var _exerSet: ExerSet = .GetDefault()
    @State private var _wait: String = "60"
    @State private var _coachPrompt: String = ""
    @State private var _showingAlert = false
    @State private var _deleteItem: String = ""
    @State private var _showAPIKeySettings = false

    var body: some View {
        NavigationStack{
            List{
                ForEach(
                    _exerSet.ExerItems.sorted {
                        $0.description().localizedCaseInsensitiveCompare($1.description()) == .orderedAscending
                    },
                    id: \.id
                ) { item in
                    NavigationLink(destination: ExerItemView(exerItem: item, history: item.GetHistory(), onDone: { onDone() }))
                    {
                        Text(item.description())
                    }
                }
            }
            .onAppear {
                print("MaintView List onAppear")
                Refresh()
            }
            .sheet(isPresented: $_showAPIKeySettings) {
                APIKeySettingsView()
            }
            Spacer()
            HStack{
                TextField("...", text: $_coachPrompt)
                Button("💾"){
                    _exerSet.CoachPrompt = _coachPrompt
                    save()
                }.font(.system(size: 24))
                Button("🔄"){
                    _coachPrompt = _exerSet.DefaultCoachPrompt()
                }.font(.system(size: 24))
                Button("🔑"){
                    _showAPIKeySettings = true
                }.font(.system(size: 24))
     }
            HStack{
                Text("Wait(secs): ")
                Spacer()
                TextField("Wait(secs)", text: $_wait)
                    .keyboardType(.numberPad)
                    .background(Color.yellow.opacity(0.2))
                    .onChange(of: _wait, initial: false) { n, newValue in
                        _exerSet.Interval = Int(newValue) ?? 60
                        _wait = newValue
                        save()
                    }
            }
            if (!_welcomed) {
                SignInWithAppleButtonView($_welcomed)
            } else {
                Button(action: {
                    signOut()
                }){
                    Text("Sign Out")
                }
            }

            NavigationLink(destination: ExerItemView(exerItem: ExerItem(Name: "", Notes: "", PerSide: false), history: nil, onDone: {onDone()})) {
                Text("New Item").bold()
            }
        }
        .refreshable {
            print("MaintView refreshable")
            Refresh()
        }
        .onAppear {
            print("MaintView Stack onAppear")
            Refresh()
        }
        .navigationTitle("Maintenance")
    }

    func signOut()
    {
        IOPAws.clearUserID()
        _welcomed = false
        Refresh()
    }
    func save()
    {
        _exerSet.Interval = Int(_wait) ?? 60
        _exerSet.CoachPrompt = _coachPrompt
        Task{
            await ExerPersist.SaveAsync(_exerSet)
            Refresh()
        }
    }
    func onDone()
    {
        print("MaintView onDone")
        Refresh()
    }

    func Refresh()
    {
        print("MaintView Refresh()")
        Task{
            _exerSet.Refresh(other: await ExerPersist.Read(), date: Date());
            _wait = String(_exerSet.Interval ?? 60)
            _coachPrompt = _exerSet.GetCoachPrompt()
        }
    }
}
