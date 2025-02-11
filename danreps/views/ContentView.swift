//
//  ContentView.swift
//  danreps
//
//  Created by Daniel Francis on 2/1/25.
//

import SwiftUI
import AVFoundation
import AVFAudio

struct ContentView: View {
    @State private var _exerSet: ExerSet = .GetDefault()
    @State private var _date: Date = Date().dateOnly
    @State private var _newName: String = ""
    @State private var _history: [UUID] = []
    @State private var _end: Date? = nil
    @State private var _countdownString: String = "-"
    @State private var _timer: Timer?
    @State private var _showClearConfirmation = false
    @State private var _rapid = GetRapid()
 
    var body: some View {
        NavigationStack{
            HStack{
                Button(action: {
                    Prev()
                }){
                    Text("⏮️")
                }
                Text(_date.danFormat + "(\(_exerSet.GetSetCount(date: _date)))")
                    .bold()
                Button(action: {
                    Next()
                }){
                    Text("⏭️")
                }
            }
            List{
                ForEach(_exerSet.ExerItems, id: \.self){ item in
                    HStack{
                        Text(item.description())
                        Spacer()
                        Text(String(_exerSet.GetRepCount(date: _date, id: item.id)))
                        Button("💥", action: {Crush(id: item.id )})
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                    }
                }
            }
            List{
                let notes = _exerSet.GetDay(_date)?.Journal ?? []
                ForEach(notes.reversed(), id: \.self){ note in
                    Text(note)
                }
            }
            if (_end != nil) {
                Text(_countdownString)
                    .font(.system(size: 48, weight: .bold)) // Large Text
                    .foregroundColor(.green) // Green Color
                    .padding()
            }
            HStack {
                Toggle("Rapid", isOn: $_rapid).onChange(of: _rapid) {
                    ContentView.SetRapid(_rapid)
                    if (_rapid == false){
                        stopTimer()
                    }
                }
                Button("😴"){
                    DNotices.requestNotificationPermission()

                    AddNote("Rest for 5")
                    startTimer(seconds: 5)
                }.font(.system(size: 36))
                Button("↩️"){
                    Undo()
                }.font(.system(size: 36))
                NavigationLink(destination: MaintView()) {
                    Text("⚙️")
                        .font(.system(size: 36))
                }
                Button("🆑"){
                    _showClearConfirmation = true
                }.font(.system(size: 36))
                .confirmationDialog("Are you sure?", isPresented: $_showClearConfirmation, titleVisibility: .visible) {
                    Button("Clear Date?", role: .destructive) {
                        ClearDay(_date)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action cannot be undone. Deleting means it never was.")
                }
            }
            .navigationTitle("Ready to Crush")
            .refreshable {
                Refresh()
            }
            .onAppear {
                Refresh()
            }
        }
    }
    static func SetRapid(_ val: Bool){
        UserDefaults.standard.set(val, forKey: "Rapid")
    }
    static func GetRapid() -> Bool{
        return UserDefaults.standard.bool(forKey: "Rapid")
    }
    func CountdownString() -> String
    {
        if (_end == nil) {
            return "-"
        }
        let timespan = _end!.timeIntervalSince(Date())
        if (timespan <= 0) {
            return "00:00"
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: timespan)!
    }
    func startTimer(seconds: Double) {
        _timer?.invalidate() // Invalidate existing timer if running
        _end = Date().addingTimeInterval(seconds)    // seconds
        _countdownString = CountdownString()
        DNotices.scheduleNotification("Back at it!", interval: seconds)
        _timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let remainingTime = _end?.timeIntervalSince(Date()) ?? 0
            _countdownString = CountdownString()
            if remainingTime <= 0 {
                //Alert()  // only works in foreground, dnotice only works in background
                _timer?.invalidate() // Stop when countdown reaches 0
            }
        }
    }
    func Alert() {
        AudioServicesPlaySystemSound(1005)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func stopTimer() {
        _timer?.invalidate() // Invalidate existing timer if running
        _end = nil
        _countdownString = CountdownString()
    }
    func Crush(id: UUID)
    {
        _exerSet.Modify(date: _date, id: id, offset: 1)
        AddNote("Crushed \(_exerSet.GetItem(id: id).Name)")
        _history.append(id);
        if (_rapid) {
            startTimer(seconds: Double(_exerSet.Interval ?? 60))
        }
        ExerPersist.SaveSync(_exerSet)
    }
    func AddNote(_ str: String) {
        _exerSet.AddNote(date: _date, str: str)
    }
    func ClearDay(_ date: Date) {
        stopTimer()
        _history.removeAll()
        _exerSet.ClearDay(date)
    }
    
    func Undo()
    {
        stopTimer()
        let id = _history.last
        if (id == nil) { return }
        AddNote("Undo \(_exerSet.GetItem(id: id!).Name)")
        _exerSet.Modify(date: _date, id: id!, offset: -1)
        ExerPersist.SaveSync(_exerSet)
        _history.removeLast()
        _end = nil
    }
    func Next()
    {
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: _date) ?? Date()
        if (newDate > Date()){
            return
        }
        _date = newDate
        _history.removeAll()
    }
    func Prev()
    {
        _date = Calendar.current.date(byAdding: .day, value: -1, to: _date) ?? Date()
        _history.removeAll()
    }
    func Refresh(){
        Task{
            _exerSet.Refresh(other: await ExerPersist.Read(), date: _date);
        }
    }

}

