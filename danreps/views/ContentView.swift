//
//  ContentView.swift
//  danreps
//
//  Created by Daniel Francis on 2/1/25.
//

import SwiftUI
import AVFoundation
import AVFAudio
import DanSwiftLib

struct ContentView: View {
    @State private var _exerSet: ExerSet = .GetDefault()
    @State private var _date: Date = Date().dateOnly
    @State private var _newName: String = ""
    @State private var _end: Date? = nil
    @State private var _countdownString: String = "-"
    @State private var _timer: Timer?
    @State private var _showClearConfirmation = false
    @State private var _rapid = GetRapid()
    @State private var _set: SetItem = SetItem.defaultItem(isDuration: false)
    @State private var _spanString: String = "0.0"
    @State private var _onDeckId: UUID? = nil
    @State private var _group: String = "ALL"
    @State private var _summary: String = ""
    @State private var _showSummary = false

    var body: some View {
        NavigationStack{
            HStack{
                Button(action: {
                    Prev()
                }){
                    Text("⏮️")
                }
                Text(_date.danFormat + "(\(_exerSet.GetSetCount(date: _date)) Σ\(_exerSet.GetSetWeight(date: _date))lbs)")
                    .bold()
                Button(action: {
                    Next()
                }){
                    Text("⏭️")
                }
            }
            List{
                ForEach(_exerSet.ExerItemsByLastDone(group: _group), id: \.self){ item in
                    VStack{
                        HStack{
                            Text(item.description())
                            Text(String(item.GetStreak()))
                            Spacer()
                            Button("", action: {Serve(item)})
                            Text(String(item.GetSetCount(date: _date)))
                        }
                        if (item.id == _onDeckId) {
                            HStack{
                                if (item.Duration == true) {
                                    TextField("Span", text: $_spanString)
                                        .keyboardType(.decimalPad)
                                        .background(Color.yellow.opacity(0.2))
                                    Picker("Units", selection: $_set.Units) {
                                        ForEach(SetItem.UnitStrings, id: \.self) { index in
                                            Text("\(index)")
                                                .tag(index)
                                        }
                                    }
                                } else {
                                    Picker("Wgt", selection: $_set.Weight) {
                                        ForEach(Array(stride(from: 0, to: 301, by: 5)), id: \.self) { index in
                                            Text("\(index)lbs")
                                                .tag(index)
                                        }
                                    }.fixedSize().frame(maxWidth: .infinity)
                                    Picker("Reps", selection: $_set.Reps) {
                                        ForEach([1,5,8,10,12,15,20,25], id: \.self) { index in
                                            Text("\(index)")
                                                .tag(index)
                                        }
                                    }.fixedSize().frame(maxWidth: .infinity)
                                }
                                Button("💥", action: {Crush(_onDeckId!)})
                                    .padding(12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }.background(BackgroundColor(item.id))
                }
            }
            let notes = _exerSet.GetJournal(date: _date)

            ScrollView {
                Text(notes.joined(separator: "\n"))
                    .font(.caption)
                    .fontWeight(.thin)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .frame(maxHeight: _exerSet.JournalHeight(notes: notes))
            if (_end != nil) {
                Text(_countdownString)
                    .font(.system(size: 48, weight: .bold)) // Large Text
                    .foregroundColor(.green) // Green Color
                    .padding()
            }
     
  
            HStack {
                Picker("Groups", selection: $_group) {
                    ForEach(_exerSet.GetGroups(), id: \.self) { group in
                        Text("\(group)")
                            .tag(group)
                    }
                }
                .onChange(of: _group) { oldValue, newValue in
                    ChangeGroup(newValue)
                }
                .fixedSize()
                Toggle("R", isOn: $_rapid).onChange(of: _rapid) { newValue, _ in
                    ContentView.SetRapid(newValue)
                    if newValue == false {
                        stopTimer()
                    }
                }
                .fixedSize()
                Button("😴"){
                    DNotices.requestNotificationPermission()
        
                    AddNote("Rest for 60")
                    startTimer(seconds: 60)
                }.font(.system(size: 36))
                Button("↩️"){
                    Undo()
                }
                NavigationLink(destination: MaintView()) {
                    Text("⚙️")
                        .font(.system(size: 36))
                }
                Button("🤖"){
                    Task {
                        await GetClaudeSummary()
                    }
                }.font(.system(size: 36))
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
                .sheet(isPresented: $_showSummary) {
                    VStack {
                        Text("AI Coach")
                            .font(.headline)
                            .padding()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                let lines = processMarkdown(_summary)
                                ForEach(0..<lines.count, id: \.self) { index in
                                    lines[index]
                                }
                            }
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button("Done") {
                            _showSummary = false
                        }
                        .padding()
                    }
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
    func BackgroundColor(_ itemId: UUID?) -> Color {
        if (itemId == _onDeckId){
            return Color.gray.opacity(0.2)
        } else {
            return .clear
        }
            
    }
    func GroupForeground(_ group: String) -> Color
    {
        if (group == _group){
            return Color.black
        } else {
            return Color.gray
        }
    }
    func ChangeGroup(_ group: String)
    {
        _group = group
        Refresh()
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
    func AddNote(_ note: String) {
        //nothing to do since we changed the way history works
    }
    func Serve(_ item: ExerItem)
    {
        _onDeckId = item.id
        _set = item.GetLastSet()
    }
    func Crush(_ id: UUID)
    {
        if (id != _onDeckId) {
            return
        }
        if (GetExerItem(id).isDuration()) {
            if let number = Float(_spanString) {
                _set.Span = number
            } else {
                _set.Span = 9.9
            }
        }
        _exerSet.Crush(id: id, date: _date, set: _set)
        if (_rapid) {
            startTimer(seconds: Double(_exerSet.Interval ?? 60))
        }
        ExerPersist.SaveSync(_exerSet)
    }
    func GetExerItem(_ id: UUID) -> ExerItem{
        return _exerSet.GetItem(id: id)
    }
    func CrushButtonText(_ id: UUID) -> String {
        if (_onDeckId == id) {
            return "💥"
        } else {
            return "🍛"
        }
    }

    func ClearDay(_ date: Date) {
        stopTimer()
        _exerSet.ClearDay(date)
    }
    
    func Undo()
    {
        stopTimer()
        //AddNote("Undo \(_exerSet.GetItem(id: id!).Name)")
        _exerSet.RemoveLast(date: _date)
        ExerPersist.SaveSync(_exerSet)
        _end = nil
    }
    func Next()
    {
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: _date) ?? Date()
        if (newDate > Date()){
            return
        }
        _date = newDate
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

    func GetClaudeSummary() async {
        let workoutData = _exerSet.DaySummary(date: _date)

        guard let apiKey = KeychainService.shared.getAPIKey() else {
            _summary = "Please set your API key using the 🔑 button"
            _showSummary = true
            return
        }

        // Validate API key format
        if !apiKey.starts(with: "sk-ant-") {
            _summary = "Invalid API key format. Key should start with 'sk-ant-'"
            _showSummary = true
            return
        }

        _summary = "Loading summary..."
        _showSummary = true

        do {
            let claude = ClaudeService()
            _summary = try await claude.prompt("This is what I did today for my workout. How did I do? \(workoutData)")
        } catch {
            _summary = "Error: \(error)\n\nAPI Key prefix: \(String(apiKey.prefix(10)))..."
        }
    }

    func processMarkdown(_ markdown: String) -> [Text] {
        var result: [Text] = []
        let lines = markdown.components(separatedBy: "\n")

        for line in lines {
            var text = Text("")
            var currentLine = line

            // Handle headers
            if currentLine.hasPrefix("### ") {
                text = Text(currentLine.replacingOccurrences(of: "### ", with: ""))
                    .font(.title3)
                    .bold()
            } else if currentLine.hasPrefix("## ") {
                text = Text(currentLine.replacingOccurrences(of: "## ", with: ""))
                    .font(.title2)
                    .bold()
            } else if currentLine.hasPrefix("# ") {
                text = Text(currentLine.replacingOccurrences(of: "# ", with: ""))
                    .font(.title)
                    .bold()
            } else {
                // Process inline markdown (bold, italic)
                text = parseInlineMarkdown(currentLine)
            }

            result.append(text)
        }

        return result
    }

    func parseInlineMarkdown(_ line: String) -> Text {
        var result = Text("")
        var currentText = line

        // Simple regex-free parsing for **bold** and *italic*
        while !currentText.isEmpty {
            if let boldRange = currentText.range(of: "\\*\\*[^*]+\\*\\*", options: .regularExpression) {
                let beforeBold = String(currentText[..<boldRange.lowerBound])
                let boldText = String(currentText[boldRange]).replacingOccurrences(of: "**", with: "")

                result = result + Text(beforeBold) + Text(boldText).bold()
                currentText = String(currentText[boldRange.upperBound...])
            } else if let italicRange = currentText.range(of: "\\*[^*]+\\*", options: .regularExpression) {
                let beforeItalic = String(currentText[..<italicRange.lowerBound])
                let italicText = String(currentText[italicRange]).replacingOccurrences(of: "*", with: "")

                result = result + Text(beforeItalic) + Text(italicText).italic()
                currentText = String(currentText[italicRange.upperBound...])
            } else {
                result = result + Text(currentText)
                break
            }
        }

        return result
    }

}

