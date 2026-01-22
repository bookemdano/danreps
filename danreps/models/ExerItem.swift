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
        case Duration
        case Sets
        case Groups
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
    func GetSetsOn(date: Date) -> [SetItem]{
        if (Sets == nil) { return [] }
        return Sets!.filter { $0.Timestamp.dateOnly == date }
    }
    
    func GetStreak() -> Int{
        // get all the item sets with this itemID in it
        if (Sets == nil) {
            return 0
        }
        let lastSet = Sets!.last ?? SetItem.defaultItem(isDuration: isDuration())
        //var streak = 0
        var dates:[Date] = []
        for item in Sets! {
            
            if (item.isGreaterThan(lastSet)) {
                if (!dates.contains(item.Timestamp.dateOnly)) {
                    dates.append(item.Timestamp.dateOnly)
                }
           }
        }
        return dates.count
    }
    func GetHistory() -> [(Date, String)] {
        if (Sets == nil) { return [] }
        return Sets!.sorted{$0.Timestamp < $1.Timestamp}.map{ set in
            if (isDuration()) {
                (set.Timestamp, "@\(set.Span!)\(set.Units!.lowercased())")
            } else {
                (set.Timestamp, "@\(set.Weight!)lbs x \(set.Reps!)")
            }
        }
    }
    func isDuration() -> Bool {
        return Duration ?? false
    }
    func GetSetCount(date: Date) -> Int {
        if (Sets == nil) { return 0 }
        return Sets!.filter { $0.Timestamp.dateOnly == date }.count
    }
    func GetGroupsString() -> String {
        if (Groups == nil) {
            return ""
        } else {
            return Groups!.joined(separator: ",")
        }
    }
    var id = UUID() // Automatically generate a unique identifier
    var Name: String
    var Notes: String
    var PerSide: Bool
    var Sets: [SetItem]? = []
    var Duration: Bool?
    var Groups: [String]?
}

