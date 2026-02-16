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
    var ExerItems: [ExerItem]
    var Interval: Int? = 60
    var CoachPrompt: String?
    var Version: String?
    var DayItems: [DayItem]?
    var AthleteProfile: AthleteProfile?
    static public let CurrentVersion = "1.0.1"  // added Sets to Items
    enum CodingKeys: String, CodingKey {
        case ExerItems
        case Interval
        case Version
        case CoachPrompt
        case DayItems
        case AthleteProfile
    }
    mutating func Refresh(other: ExerSet, date: Date){
        ExerItems.removeAll(keepingCapacity: false)
        ExerItems.append(contentsOf: other.ExerItems)
        Interval = other.Interval
        
        Version = other.Version
        CoachPrompt = other.CoachPrompt
        
        if other.DayItems != nil {
            DayItems = other.DayItems
        }
        AthleteProfile = other.AthleteProfile
    }
    func GetCoachPrompt() -> String{
        if (CoachPrompt == nil) {
            return DefaultCoachPrompt()
        }
        return CoachPrompt!
    }
    func DefaultCoachPrompt() -> String{
        return "This is my workout. Tell me how I did and score it out of 10. Don't use tables."
    }

    mutating func UpdateVersion()
    {
        // nil to 1.0.0
        /*if (Version == nil) {
         for dayIndex in ExerDays.indices {
         for setIndex in ExerDays[dayIndex].ItemSets.indices {
         if (ExerDays[dayIndex].ItemSets[setIndex].Time == nil) {
         ExerDays[dayIndex].ItemSets[setIndex].Time = ExerDays[dayIndex].Date
         }
         }
         }
         }
         if (Version == "1.0.0") {
         for i in ExerItems.indices {
         ExerItems[i].Sets = []
         for set in GetHistorySets(itemId: ExerItems[i].id) {
         ExerItems[i].Sets?.append(SetItem(Weight: set.1, Reps: set.2, Timestamp: set.0))
         }
         }
         }*/
        Version = ExerSet.CurrentVersion
    }
    func GetGroups() -> [String]
    {
        var rv = [String]()
        ExerItems.forEach { item in
            item.Groups?.forEach{ group in
                if (!rv.contains(group)) {
                    rv.append(group)
                }
            }
        }
        rv = rv.sorted()
        rv.insert("ALL", at: 0)
        return rv
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
        exerItems.append(ExerItem(Name: "Swimming", Notes: "", PerSide: false, Duration: true))
    return ExerSet(ExerItems: exerItems)
    }
    
    func GetItem(id: UUID) -> ExerItem{
        return ExerItems.first(where: {$0.id == id}) ?? ExerItem(Name: "Missing", Notes: "", PerSide: false)
    }
    func GetSetCount(date: Date) -> Int{
        return ExerItems.reduce(0) { total, item in
            guard let sets = item.Sets else { return total }
            return total + sets.filter { $0.Timestamp.dateOnly == date.dateOnly }.count
        }
    }
    
    func GetSetWeight(date: Date) -> Int{
        return ExerItems.reduce(0) { total, item in
            guard let sets = item.Sets else { return total }
            var multiplier = 1
            if (item.PerSide) { multiplier = 2 }
            return total + sets.filter { $0.Timestamp.dateOnly == date.dateOnly }
                .reduce(0) { $0 + ($1.totalWeight() * multiplier) }
        }
    }
    mutating func RemoveLast(date: Date){
        let item = ExerItems.sorted { $0.GetLastSetOn(date: date).Timestamp > $1.GetLastSetOn(date: date).Timestamp }.first
        if (item == nil) {
            return
        }
        let lastSet = item!.GetLastSetOn(date: date)
        
        guard let idx = ExerItems.firstIndex(where: { $0.id == item!.id }) else { return }
        guard var sets = ExerItems[idx].Sets else { return }

        sets.removeAll {
            $0.Timestamp == lastSet.Timestamp
        }

        ExerItems[idx].Sets = sets
    }
    func GetGroupsExceptAll() -> [String] {
        var rv = [String]()
        ExerItems.forEach { item in
            item.Groups?.forEach{ group in
                if (!rv.contains(group)) {
                    rv.append(group)
                }
            }
        }
        return rv.sorted()
    }
    mutating func RemoveGroup(_ group: String) {
        for i in ExerItems.indices {
            ExerItems[i].Groups?.removeAll(where: { $0 == group })
        }
    }
    mutating func ToggleExerciseGroup(exerciseId: UUID, group: String) {
        guard let idx = ExerItems.firstIndex(where: { $0.id == exerciseId }) else { return }
        if ExerItems[idx].Groups == nil {
            ExerItems[idx].Groups = []
        }
        if ExerItems[idx].Groups!.contains(group) {
            ExerItems[idx].Groups!.removeAll(where: { $0 == group })
        } else {
            ExerItems[idx].Groups!.append(group)
        }
    }
    func ExerItemsByLastDone(group: String) -> [ExerItem] {
        if (group.uppercased() == "ALL") {
            return ExerItems.sorted { $0.GetLastSet().Timestamp > $1.GetLastSet().Timestamp }
        } else {
            return ExerItems
                .filter { $0.Groups?.contains(group) == true }
                .sorted { $0.GetLastSet().Timestamp > $1.GetLastSet().Timestamp }
        }
    }
    
    mutating func ClearDay(_ date: Date) {
        for i in ExerItems.indices {
            if ExerItems[i].Sets == nil { continue }
            ExerItems[i].Sets!.removeAll {
                $0.Timestamp.dateOnly == date.dateOnly
            }
        }
    }
    func JournalHeight(notes: [String]) -> CGFloat {
        let rv = notes.count * 20
        if (rv > 150) {
            return 150;
        }
        return CGFloat(rv)
    }
    func GetJournal(date: Date) -> [String] {
        var entries: [String] = []
        for item in ExerItems {
            guard let sets = item.Sets else { continue }
            for set in sets where set.Timestamp.dateOnly == date.dateOnly {
                
                entries.append(set.getJournalString(itemName: item.Name))
            }
        }
        return entries.sorted(by: >)
    }
    func DaySummary(date: Date) -> String {
        let items = ExerItems.filter { $0.GetSetCount(date: date) > 0 }
        var rv:[String] = [SetItem.getCsvHeader()]

        for item in items {
            let sets = item.GetSetsOn(date: date)
            for set in sets {
                rv.append(set.getCsv(itemName: item.Name))
            }
        }
        return rv.joined(separator: "\n")
    }
    func getCoachingString(for date: Date) -> String? {
        guard let dayItem = DayItems?.first(where: { $0.Date.dateOnly == date.dateOnly }) else {
            return nil
        }
        return dayItem.Coaching
    }
    mutating func setCoachingString(for date: Date, coaching: String?) {

        if DayItems == nil {
            DayItems = []
        }
        if (coaching == nil) {
            DayItems!.removeAll(where: { $0.Date.dateOnly == date.dateOnly })
            return
        }
        if let index = DayItems?.firstIndex(where: { $0.Date.dateOnly == date.dateOnly }) {
            DayItems?[index].Coaching = coaching!
        } else {
            DayItems?.append(DayItem(Date: date.dateOnly, Coaching: coaching!))
        }
    }
    
    func ComputeProfileData() -> String {
        var lines: [String] = []
        let cal = Calendar.current
        let today = Date()
        guard let fourWeeksAgo = cal.date(byAdding: .day, value: -28, to: today) else {
            return "No data available"
        }

        // Collect all sets from the last 4 weeks grouped by date
        var dateSets: [Date: [(String, SetItem, Bool)]] = [:] // date -> [(name, set, perSide)]
        for item in ExerItems {
            guard let sets = item.Sets else { continue }
            for set in sets where set.Timestamp >= fourWeeksAgo {
                let d = set.Timestamp.dateOnly
                dateSets[d, default: []].append((item.Name, set, item.PerSide))
            }
        }

        let sortedDates = dateSets.keys.sorted()
        let sessionsPerWeek = sortedDates.isEmpty ? 0.0 : Float(sortedDates.count) / 4.0
        lines.append("TRAINING FREQUENCY: \(sortedDates.count) sessions in 4 weeks (\(String(format: "%.1f", sessionsPerWeek))/week)")

        // Volume per group per week
        let groups = GetGroupsExceptAll()
        if !groups.isEmpty {
            lines.append("\nVOLUME BY GROUP (sets per week, last 4 weeks):")
            for group in groups {
                let groupItems = ExerItems.filter { $0.Groups?.contains(group) == true }
                var weeklyCounts: [Int] = []
                for weekOffset in (0..<4).reversed() {
                    guard let weekStart = cal.date(byAdding: .day, value: -(weekOffset + 1) * 7, to: today),
                          let weekEnd = cal.date(byAdding: .day, value: -weekOffset * 7, to: today) else { continue }
                    var count = 0
                    for item in groupItems {
                        guard let sets = item.Sets else { continue }
                        count += sets.filter { $0.Timestamp >= weekStart && $0.Timestamp < weekEnd }.count
                    }
                    weeklyCounts.append(count)
                }
                lines.append("  \(group): \(weeklyCounts.map(String.init).joined(separator: ", "))")
            }
        }

        // Estimated 1RMs for weight exercises
        lines.append("\nESTIMATED 1RMs:")
        for item in ExerItems where !item.isDuration() {
            guard let sets = item.Sets, !sets.isEmpty else { continue }
            var best1RM = 0
            var bestSet: SetItem?
            for set in sets {
                guard let w = set.Weight, let r = set.Reps, w > 0, r > 0 else { continue }
                let e1rm = Int(Double(w) * (1.0 + Double(r) / 30.0))
                if e1rm > best1RM {
                    best1RM = e1rm
                    bestSet = set
                }
            }
            if let bs = bestSet, let bw = bs.Weight, let br = bs.Reps {
                lines.append("  \(item.Name): \(best1RM)lbs (from \(bw)x\(br))")
            }
        }

        // Last 4 session summaries
        lines.append("\nLAST 4 SESSIONS:")
        for date in sortedDates.suffix(4) {
            guard let daySets = dateSets[date] else { continue }
            let timestamps = daySets.map { $0.1.Timestamp }
            let minT = timestamps.min() ?? date
            let maxT = timestamps.max() ?? date
            let duration = Int(maxT.timeIntervalSince(minT) / 60)
            let totalVol = daySets.reduce(0) { total, entry in
                let multiplier = entry.2 ? 2 : 1
                return total + entry.1.totalWeight() * multiplier
            }
            let exercises = Array(Set(daySets.map { $0.0 })).sorted()
            lines.append("  \(date.dateOnly): \(daySets.count) sets, ~\(duration)min, \(totalVol)lbs vol")
            lines.append("    Exercises: \(exercises.joined(separator: ", "))")
        }

        // Progression notes
        lines.append("\nPROGRESSION NOTES:")
        for item in ExerItems where !item.isDuration() {
            guard let sets = item.Sets, sets.count >= 2 else { continue }
            guard let lastSet = sets.last,
                  let w = lastSet.Weight, let r = lastSet.Reps, w > 0, r > 0 else { continue }
            let lastE1RM = Int(Double(w) * (1.0 + Double(r) / 30.0))
            let allMax = sets.compactMap { s -> Int? in
                guard let sw = s.Weight, let sr = s.Reps, sw > 0, sr > 0 else { return nil }
                return Int(Double(sw) * (1.0 + Double(sr) / 30.0))
            }.max() ?? 0
            if lastE1RM >= allMax && allMax > 0 {
                lines.append("  \(item.Name): PR - \(w)x\(r) (e1RM: \(lastE1RM)lbs)")
            }
        }

        return lines.joined(separator: "\n")
    }

    // crush
    mutating func Crush(id: UUID, date: Date, set: SetItem)
    {
        // Find the ExerItem in ExerItems by id
        guard let idx = ExerItems.firstIndex(where: { $0.id == id }) else { return }
        if (ExerItems[idx].Sets == nil) { ExerItems[idx].Sets = [] }
        var timestamp = date
        if (date.dateOnly == Date().dateOnly) {
            timestamp = Date()  // include time
        } else {
            timestamp.addTimeInterval(23 * 60 * 60)
        }
        if (ExerItems[idx].isDuration()) {
            ExerItems[idx].Sets?.append(SetItem(Span: set.Span, Units: set.Units, Timestamp: timestamp))
        } else {
            ExerItems[idx].Sets?.append(SetItem(Weight: set.Weight, Reps: set.Reps, Timestamp: timestamp))
        }
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
struct DayItem : Codable
{
    var Date: Date
    var Coaching: String
    enum CodingKeys: String, CodingKey {
        case Date
        case Coaching
    }
}
