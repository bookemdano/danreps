//
//  MoodSet.swift
//  danreps
//
//  Created by Daniel Francis on 2/1/25.
//

import Foundation

struct ExerSet : Codable
{
    var ExerDays: [ExerDay]
    var ExerItems: [ExerItem]
    var Interval: Int? = 60
    enum CodingKeys: String, CodingKey {
        case ExerDays
        case ExerItems
        case Interval
    }
    mutating func Refresh(other: ExerSet, date: Date){
        ExerDays.removeAll(keepingCapacity: false)
        ExerDays.append(contentsOf: other.ExerDays)
        ExerItems.removeAll(keepingCapacity: false)
        ExerItems.append(contentsOf: other.ExerItems)
        Interval = other.Interval
        if (GetDay(date) == nil) {
            ClearDay(date)
        }
    }
    static func GetDefault() -> ExerSet
    {
        var exerItems:[ExerItem] = []
        exerItems.append(ExerItem(Name: "DB Curls", Reps: 10, Notes: "", PerSide: true))
        exerItems.append(ExerItem(Name: "BB Half squat", Reps: 15, Notes: "", PerSide: false))
        exerItems.append(ExerItem(Name: "BB Curls", Reps: 10, Notes: "", PerSide: false))
        exerItems.append(ExerItem(Name: "BB Clean", Reps: 10, Notes: "", PerSide: false))
        return ExerSet(ExerDays: [], ExerItems: exerItems)
    }
    
    func GetDayItems(date: Date) -> [ExerItem]
    {
        let reps = GetDay(date)?.Sets
        if (reps == nil) {
            return []
        }
        return reps!.map({GetItem(id: $0.key)}).sorted(by: {$0.Name < $1.Name})
    }
    
    func GetItem(id: UUID) -> ExerItem{
        return ExerItems.first(where: {$0.id == id}) ?? ExerItem(Name: "Missing", Reps: 1, Notes: "", PerSide: false)
    }
    func GetSetCount(date: Date) -> Int{
        let day = GetDay(date)
        if (day == nil) { return 0 }
        
        return day!.Sets.values.reduce(0, +)
    }
    func GetRepCount(date: Date, id: UUID) -> Int{
        let day = GetDay(date)
        if (day == nil) { return 0 }
        return day!.Sets.first(where: {$0.key == id})?.value ?? 0
    }
    func GetDay(_ date: Date) -> ExerDay?{
        return ExerDays.first(where: {$0.Date == date.dateOnly})
    }
    mutating func Modify(date: Date, id: UUID, offset: Int)
    {
        var index = ExerDays.firstIndex(where: {$0.Date == date})
        if (index == nil)
        {
            ClearDay(date)
            index = ExerDays.firstIndex(where: {$0.Date == date})
        }
        let oldReps = ExerDays[index!].Sets[id] ?? 0
        ExerDays[index!].Sets[id]  = oldReps + offset
    }
    mutating func AddNote(date: Date, str: String) {
        let index = ExerDays.firstIndex(where: {$0.Date == date})
        if (index == nil) { return }
        ExerDays[index!].Journal.append("\(Date().shortTime) \(str)")
    }
    mutating func ClearDay(_ date: Date) {
        ExerDays.removeAll(where: {$0.Date == date})
        var day = ExerDay(Date: date)
        ExerItems.forEach { item in
            day.Sets[item.id] = 0
        }
        ExerDays.append(day)
    }
    
    /*
     mutating func NewMoodItem(name: String, date: Date)
     {
         ExerItems.append(ExerItem(Name: name))
     }
     mutating func Move(date: Date, moodItem: ExerItem) dp Rep
    {
        if (!ExerDays.contains(where: {$0.Date == date})) {
            ExerDays.append(ExerDay(Date: date))
        }
        let index = ExerDays.firstIndex(where: {$0.Date == date})!
        var moveTo: MoodStatusEnum = .NA
        if (moveFrom == .Up) { moveTo = .Down }
        else if (moveFrom == .NA) { moveTo = .Up }
        else { moveTo = .NA }
        
        if (moveFrom != .NA) {
            ExerDays[index].Moods.removeValue(forKey: moodItem.id)
        }
        if (moveTo != .NA) {
            ExerDays[index].Moods[moodItem.id] = moveTo
        }
    }
     */
}

struct ExerDay : Codable
{
    var Date: Date
    var Sets: [UUID: Int] = [:]
    var Journal: [String] = []

    enum CodingKeys: String, CodingKey {
        case Date
        case Sets
        case Journal
    }
}

struct ExerItem : Codable, Hashable, Identifiable, Comparable
{
    static func < (lhs: ExerItem, rhs: ExerItem) -> Bool {
        return lhs.Name < rhs.Name
    }
    func description() -> String {
        var rv = "\(Name)"
        if (Reps != 10){
            rv = rv + " (\(Reps))"
        }
        if (PerSide) {
            rv = rv + " (2x)"
        }
        if (!Notes.isEmpty) {
            rv = rv + "*"
        }

        return rv
    }
    enum CodingKeys: String, CodingKey {
        case id
        case Name
        case Reps
        case Notes
        case PerSide
    }

    var id = UUID() // Automatically generate a unique identifier
    var Name: String
    var Reps: Int
    var Notes: String
    var PerSide: Bool
}
struct ExerPersist {
    static let _iop = IOPAws(app: "DanReps")

    static func JsonName() -> String{
        let rv = "exers\(IOPAws.GetOwner()).json"
        return rv
    }
    
    static func Read() async -> ExerSet{
        
        let content = await _iop.Read(dir: "Data", file: JsonName())
        if (content.isEmpty){
            return ExerSet.GetDefault()
        }
        
        let jsonString = content
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let rv = try JSONDecoder().decode(ExerSet.self, from: jsonData)
                return rv
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }
        return ExerSet.GetDefault()
    }
    static func Update(id: UUID, name: String, reps: Int, perSide: Bool, notes: String) async
    {
        Task{
            var exerSet = await Read()

            let index = exerSet.ExerItems.firstIndex(where: { $0.id == id})
            if (index == nil)
            {
                let item = ExerItem(Name: name, Reps: reps, Notes: notes, PerSide: perSide)
                exerSet.ExerItems.append(item)
            }
            else
            {
                exerSet.ExerItems[index!].Name = name
                exerSet.ExerItems[index!].Reps = reps
                exerSet.ExerItems[index!].PerSide = perSide
                exerSet.ExerItems[index!].Notes = notes
            }

            await SaveAsync(exerSet)
        }
    }
    static func Remove(id: UUID) async
    {
        var exerSet = await Read()
        exerSet.ExerItems.removeAll(where: { $0.id == id})
        await SaveAsync(exerSet)
    }
    static func SaveSync(_ exerSet: ExerSet)
    {
        Task
        {
            await SaveAsync(exerSet)
        }
    }
    static func SaveAsync(_ exerSet: ExerSet) async
    {
        do {
            let jsonData = try JSONEncoder().encode(exerSet)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                if (await _iop.Write(dir: "Data", file: JsonName(), content: jsonString) == false){
                    print("Write failed!")
                }
            }
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
}
