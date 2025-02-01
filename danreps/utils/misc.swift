//
//  misc.swift
//  danreps
//
//  Created by Daniel Francis on 2/1/25.
//

import Foundation

extension Date {
    /// Returns the date with time set to midnight (00:00:00)
    var dateOnly: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self)
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self) ?? Date()
    }
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self) ?? Date()
    }
    var danFormat: String {
        //let n = LastDone!.formatted(date: .numeric, time: .omitted)
        //let c = LastDone!.formatted(date: .complete, time: .omitted)
        //let l = LastDone!.formatted(date: .long, time: .omitted)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // Specify the format
        return formatter.string(from: self)
    }
}
