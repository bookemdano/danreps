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
        exerItems.append(ExerItem(Name: "DB Curls", Notes: "", PerSide: true))
        exerItems.append(ExerItem(Name: "Kettlebells", Notes: "", PerSide: false))
        exerItems.append(ExerItem(Name: "BB Overhead", Notes: "", PerSide: false))
        exerItems.append(ExerItem(Name: "BB Curls", Notes: "", PerSide: false))
        exerItems.append(ExerItem(Name: "BB Bench", Notes: "", PerSide: false))
        exerItems.append(ExerItem(Name: "BB Clean", Notes: "", PerSide: false))
        return ExerSet(ExerDays: [], ExerItems: exerItems)
    }
    
    func GetDayItems(date: Date) -> [ExerItem]
    {
        let reps = GetDay(date)?.ItemSets
        if (reps == nil) {
            return []
        }
        return reps!.map({GetItem(id: $0.ItemId)}).sorted(by: {$0.Name < $1.Name})
    }
    
    func GetItem(id: UUID) -> ExerItem{
        return ExerItems.first(where: {$0.id == id}) ?? ExerItem(Name: "Missing", Notes: "", PerSide: false)
    }
    func GetSetCount(date: Date) -> Int{
        let day = GetDay(date)
        if (day == nil) { return 0 }
        
        return day!.ItemSets.count
    }
    func GetSetCount(date: Date, id: UUID) -> Int{
        let day = GetDay(date)
        if (day == nil) { return 0 }
        return day!.ItemSets.count(where: {$0.ItemId == id})
    }
    func GetDay(_ date: Date) -> ExerDay?{
        return ExerDays.first(where: {$0.Date == date.dateOnly})
    }
    mutating func Add(date: Date, id: UUID, weight: Int, reps: Int)
    {
        var index = ExerDays.firstIndex(where: {$0.Date == date})
        if (index == nil)
        {
            ClearDay(date)
            index = ExerDays.firstIndex(where: {$0.Date == date})
        }
        let newItem = ItemSet(ItemId: id, Weight: weight, Reps: reps)
        ExerDays[index!].ItemSets.append(newItem)
        
        var itemIndex = ExerItems.firstIndex(where: {$0.id == id})
        if (itemIndex != nil) {
            ExerItems[itemIndex!].LastWeight = weight
            ExerItems[itemIndex!].LastReps = reps
        }
    }
    mutating func Remove(date: Date, id: UUID)
    {
        let index = ExerDays.firstIndex(where: {$0.Date == date})
        if (index == nil) { return }
        let itemIndex = ExerDays[index!].ItemSets.lastIndex(where: {$0.ItemId == id})
        if (itemIndex == nil) { return }
        ExerDays[index!].ItemSets.remove(at: itemIndex!);
    }
    mutating func AddNote(date: Date, str: String) {
        let index = ExerDays.firstIndex(where: {$0.Date == date})
        if (index == nil) { return }
        ExerDays[index!].Journal.append("\(Date().shortTime) \(str)")
    }
    mutating func ClearDay(_ date: Date) {
        ExerDays.removeAll(where: {$0.Date == date})
        var day = ExerDay(Date: date)
        day.ItemSets = []
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
    var ItemSets: [ItemSet] = []
    var Journal: [String] = []

    enum CodingKeys: String, CodingKey {
        case Date
        case ItemSets
        case Journal
    }
}
struct ItemSet : Codable
{
    var ItemId: UUID
    var Weight: Int
    var Reps: Int
    enum CodingKeys: String, CodingKey {
        case ItemId
        case Weight
        case Reps
    }
}
struct ExerItem : Codable, Hashable, Identifiable, Comparable
{
    static func < (lhs: ExerItem, rhs: ExerItem) -> Bool {
        return lhs.Name < rhs.Name
    }
    func description() -> String {
        var rv = "\(Name)"
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
        case Notes
        case PerSide
        case LastWeight
        case LastReps
    }

    var id = UUID() // Automatically generate a unique identifier
    var Name: String
    var Notes: String
    var PerSide: Bool
    var LastWeight: Int?
    var LastReps: Int?
}
struct ExerPersist {
    static let _iop = IOPAws(app: "DanReps")

    static func JsonName() -> String{
        var userID = IOPAws.getUserID()
        if (userID == nil){
            userID = "Template"
        }
        return "exers\(userID!).json"
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
    static func Update(id: UUID, name: String, perSide: Bool, notes: String) async
    {
        Task{
            var exerSet = await Read()

            let index = exerSet.ExerItems.firstIndex(where: { $0.id == id})
            if (index == nil)
            {
                let item = ExerItem(Name: name, Notes: notes, PerSide: perSide)
                exerSet.ExerItems.append(item)
            }
            else
            {
                exerSet.ExerItems[index!].Name = name
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
        if (IOPAws.getUserID() == nil) {
            print("Don't save without userID")
            return
        }
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
