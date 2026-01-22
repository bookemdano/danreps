//
//  SetItem.swift
//  danreps
//
//  Created by Daniel Francis on 1/22/26.
//
import Foundation
import DanSwiftLib

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

enum UnitEnum {
    case NA
    case Yards
    case Meters
    case Miles
    case Kilometers
}
