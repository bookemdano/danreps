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
    }

    var id = UUID() // Automatically generate a unique identifier
    var Name: String
    var Notes: String
    var PerSide: Bool
}
