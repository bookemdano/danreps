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
    enum CodingKeys: String, CodingKey {
        case ExerDays
        case ExerItems
    }
    mutating func Refresh(other: ExerSet, date: Date){
        ExerDays.removeAll(keepingCapacity: false)
        ExerDays.append(contentsOf: other.ExerDays)
        ExerItems.removeAll(keepingCapacity: false)
        ExerItems.append(contentsOf: other.ExerItems)
        
        if (GetDay(date) == nil) {
            var day = ExerDay(Date: date)
            ExerItems.forEach { item in
                day.Reps[item.id] = 0
            }
            ExerDays.append(day)
        }
    }
    static func GetDefault() -> ExerSet
    {
        var exerItems:[ExerItem] = []
        exerItems.append(ExerItem(Name: "DB Curls"))
        exerItems.append(ExerItem(Name: "BB Half squat"))
        exerItems.append(ExerItem(Name: "BB Curls"))
        exerItems.append(ExerItem(Name: "BB Clean"))
        return ExerSet(ExerDays: [], ExerItems: exerItems)
    }
    
    func GetItems(date: Date) -> [ExerItem]
    {
        let reps = GetDay(date)?.Reps
        if (reps == nil) {
            return []
        }
        let rv = reps!.map({GetItem(id: $0.key)}).sorted(by: {$0.Name < $1.Name})
        //return ExerItems
        return rv
    }
    func GetItem(id: UUID) -> ExerItem{
        return ExerItems.first(where: {$0.id == id}) ?? ExerItem(Name: "Missing")
    }
    func GetRepCount(date: Date, id: UUID) -> Int{
        let day = GetDay(date)
        if (day == nil) { return 0 }
        return day!.Reps.first(where: {$0.key == id})?.value ?? 0
    }
    func GetDay(_ date: Date) -> ExerDay?{
        return ExerDays.first(where: {$0.Date == date.dateOnly})
    }
    mutating func NewMoodItem(name: String, date: Date)
    {
        ExerItems.append(ExerItem(Name: name))
    }
    
    /*mutating func Move(date: Date, moodItem: ExerItem) dp Rep
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
    var Reps: [UUID: Int] = [:]
  
    enum CodingKeys: String, CodingKey {
        case Date
        case Reps
    }
}

struct ExerItem : Codable, Hashable, Identifiable, Comparable
{
    static func < (lhs: ExerItem, rhs: ExerItem) -> Bool {
        return lhs.Name < rhs.Name
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case Name
    }

    var id = UUID() // Automatically generate a unique identifier
    var Name: String
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
    static func SaveSync(exerSet: ExerSet)
    {
        Task
        {
            await SaveAsync(exerSet: exerSet)
        }
    }
    static func SaveAsync(exerSet: ExerSet) async
    {
        do {
            let jsonData = try JSONEncoder().encode(exerSet)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                await _iop.Write(dir: "Data", file: JsonName(), content: jsonString)
            }
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
}
