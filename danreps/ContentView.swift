//
//  ContentView.swift
//  danreps
//
//  Created by Daniel Francis on 2/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var _exerSet: ExerSet = .GetDefault()
    @State private var _date: Date = Date().dateOnly
    @State private var _newName: String = ""
    
    var body: some View {
        NavigationView{
            VStack{
                HStack{
                    Button(action: {
                        Prev()
                    }){
                        Text("⏮️")
                    }
                    Text(_date.danFormat)
                        .bold()
                    Button(action: {
                        Next()
                    }){
                        Text("⏭️")
                    }
                }
                List{
                    ForEach(_exerSet.GetItems(date: _date), id: \.self){ item in
                        HStack{
                            Text(item.Name)
                            Spacer()
                            Text(String(_exerSet.GetRepCount(date: _date, id: item.id)))
                            Button(action: {
                                print("Did something")
                            }){
                                Text("Change")
                            }
                        }
                    }
                }
             
            }
        }
        //.navigationTitle("Reps")
        .refreshable {
            Refresh()
        }
        .onAppear {
            Refresh()
        }
    }
    func Next()
    {
        _date = Calendar.current.date(byAdding: .day, value: 1, to: _date) ?? Date()
        if (_date > Date()){
            _date = Date()
        }
    }
    func Prev()
    {
        _date = Calendar.current.date(byAdding: .day, value: -1, to: _date) ?? Date()
    }
    func Refresh(){
        Task{
            _exerSet.Refresh(other: await ExerPersist.Read(), date: _date);
        }
    }

}

