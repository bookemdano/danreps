//
//  MoodSet.swift
//  danreps
//
//  Created by Daniel Francis on 2/1/25.
//

import Foundation
import DanSwiftLib

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
    func GetStreak(_ id: UUID) -> Int{
        // get all the item sets with this itemID in it
        let matchingItemSets = ExerDays
            .flatMap { $0.ItemSets }
            .filter { $0.ItemId == id }
        let lastWeight = matchingItemSets.last?.Weight ?? 50
        let lastReps = matchingItemSets.last?.Reps ?? 10
        var streak = 0
        for item in matchingItemSets.reversed() {
            if (item.Reps >= lastReps && item.Weight >= lastWeight) {
                streak += 1
            }
        }
        return streak
    }
    func GetLastItemSet(_ id: UUID) -> ItemSet{
        for day in ExerDays.reversed() {
            if let match = day.ItemSets.last(where: { $0.ItemId == id }) {
                return match
            }
        }
        return ItemSet(ItemId: UUID(), Weight:50, Reps: 10)
        
        /*let matchingItemSets = ExerDays
            .flatMap { $0.ItemSets }
            .filter { $0.ItemId == id }
        return matchingItemSets.last ?? ItemSet(ItemId: UUID(), Weight:50, Reps: 10)*/
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
        let newItem = ItemSet(ItemId: id, Weight: weight, Reps: reps, Time: Date())
        ExerDays[index!].ItemSets.append(newItem)
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

    public func GetHistory(item: ExerItem) -> [(Date, String)] {
        return ExerDays.flatMap { day -> [(Date, String)] in
            day.ItemSets.compactMap { set -> (Date, String)? in
                if set.ItemId == item.id {
                    return (set.Time ?? day.Date, "@\(set.Weight)lbs x \(set.Reps)")
                }
                return nil
            }
        }
    }
    func GetJournal(date: Date) -> [String] {
        let day = GetDay(date)
        if (day == nil) {
            return []
        }
        let journalEntries = day!.ItemSets.map { itemSet -> String in
            let item = GetItem(id: itemSet.ItemId)
            //"Crushed \(GetExerItem(id).Name) @\(_weight)lbs x \(_reps)"
            return "\((itemSet.Time ?? Date().dateOnly).shortTime) Crushed \(item.Name) @\(itemSet.Weight)lbs x \(itemSet.Reps)"
        }
        return journalEntries
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
    var Time: Date?
    enum CodingKeys: String, CodingKey {
        case ItemId
        case Weight
        case Reps
        case Time
    }
}


