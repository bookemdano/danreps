//
//  ExerItem.swift
//  danreps
//
//  Created by Daniel Francis on 4/27/25.
//
import Foundation
import DanSwiftLib

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
        case Sets
    }

    // uncrush
    /*mutating func Remove(date: Date, id: UUID) {
        let index = Sets.firstIndex(where: {$0.Date == date})
        if (index == nil) { return }
        let itemIndex = ExerDays[index!].ItemSets.lastIndex(where: {$0.ItemId == id})
        if (itemIndex == nil) { return }
        ExerDays[index!].ItemSets.remove(at: itemIndex!);
    }*/
    func GetLastSet() -> SetItem{
        var rv: SetItem?
        if (Sets != nil) {
            rv = Sets?.last
        }
        return rv ?? SetItem(Weight:50, Reps: 10, Timestamp: Date.distantPast)
    }
    func GetLastSetOn(date: Date) -> SetItem{
        var rv: SetItem?
        if (Sets != nil) {
            rv = Sets?.last(where: {$0.Timestamp.dateOnly == date})
        }
        return rv ?? SetItem(Weight:50, Reps: 10, Timestamp: Date.distantPast)
    }
    
    func GetStreak() -> Int{
        // get all the item sets with this itemID in it
        if (Sets == nil) {
            return 0
        }
        let lastWeight = Sets!.last?.Weight ?? 50
        let lastReps = Sets!.last?.Reps ?? 10
        //var streak = 0
        var dates:[Date] = []
        for item in Sets! {
            if (item.Reps >= lastReps && item.Weight >= lastWeight) {
                if (!dates.contains(item.Timestamp.dateOnly)) {
                    dates.append(item.Timestamp.dateOnly)
                }
           }
        }
        return dates.count
    }
    func GetHistory() -> [(Date, String)] {
        if (Sets == nil) { return [] }
        return Sets!.map { set in
            (set.Timestamp, "@\(set.Weight)lbs x \(set.Reps)")
        }
    }
    func GetSetCount(date: Date) -> Int {
        if (Sets == nil) { return 0 }
        return Sets!.filter { $0.Timestamp.dateOnly == date }.count
    }
    var id = UUID() // Automatically generate a unique identifier
    var Name: String
    var Notes: String
    var PerSide: Bool
    var Sets: [SetItem]? = []
}
struct SetItem : Codable, Hashable
{
    var Weight: Int
    var Reps: Int
    var Timestamp: Date
    enum CodingKeys: String, CodingKey {
        case Weight
        case Reps
        case Timestamp
    }
}
