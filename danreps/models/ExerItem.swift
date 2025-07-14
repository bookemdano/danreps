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
enum UnitEnum {
    case NA
    case Yards
    case Meters
    case Miles
    case Kilometers
}
struct SetItem : Codable, Hashable
{
    var Weight: Int?
    var Reps: Int?
    var Span: Float?
    var Units: String?
    var Timestamp: Date
    static func defaultItem(isDuration: Bool) -> SetItem {
        if (isDuration) {
            return SetItem(Weight: nil, Reps: nil, Span: 0, Units: "Yards", Timestamp: Date.distantPast)
        } else {
            return SetItem(Weight: 0, Reps: 0, Span: nil, Units: nil, Timestamp: Date.distantPast)
        }
    }
    static var UnitStrings:[String] {
        return ["Yards", "Miles", "Meters", "KM", "Mins", "Hours"]
    }
    var UnitsEnum: UnitEnum {
        switch Units {
        case "yards":
            return .Yards
        case "meters":
            return .Meters
        case "miles":
            return .Miles
        case "kilometers":
            return .Kilometers
        default:
            return .NA
        }
    }
    // return span in meters
    var StandardSpan: Float {
        if (!isDuration()) {
            return 0.0
        } else {
            if (UnitsEnum == .Yards) {
                return Span! * 0.9144
            }
            else if (UnitsEnum == .Miles) {
                return Span! * 1609.344
            }
            else if (UnitsEnum == .Kilometers) {
                return Span! * 1000
            }
            else {  //if (UnitsEnum == .Meters) {
                return Span!
            }
        }
    }
    func isGreaterThan(_ other: SetItem) -> Bool {
        if (isDuration()) {
            return (StandardSpan >= other.StandardSpan)
        } else {
            return (Reps! >= other.Reps! && Weight! >= other.Weight!)
        }
    }
    func getJournalString(itemName: String) -> String {
        let timeStr = (Timestamp.shortTime)
        if (isDuration()) {
            return "\(timeStr) Crushed \(itemName) @\(Span!)\(Units!)"
        } else {
            return "\(timeStr) Crushed \(itemName) @\(Weight!)lbs x \(Reps!)"
        }
    }
    func isDuration() -> Bool {
        return (Span != nil)
    }
    func totalWeight() -> Int {
        if (isDuration()) {
            return 0
        } else {
            return Weight! * Reps!
        }
    }
    enum CodingKeys: String, CodingKey {
        case Weight
        case Reps
        case Span
        case Units
        case Timestamp
    }
}
