//
//  ExerPersist.swift
//  danreps
//
//  Created by Daniel Francis on 4/27/25.
//
import Foundation
import DanSwiftLib

struct ExerPersist {
    static func Read() async -> ExerSet{
        guard let userID = IOPAws.getUserID() else {
            return ExerSet.GetDefault()
        }

        do {
            let content = try await ApiService.shared.read(userId: userID)
            if content.isEmpty {
                return ExerSet.GetDefault()
            }
            if let jsonData = content.data(using: .utf8) {
                var rv = try JSONDecoder().decode(ExerSet.self, from: jsonData)
                if (rv.Version != ExerSet.CurrentVersion) {
                    rv.UpdateVersion()
                }
                return rv
            }
        } catch {
            print("Failed to read/decode JSON: \(error)")
        }
        return ExerSet.GetDefault()
    }
    static func Update(id: UUID, name: String, perSide: Bool, duration: Bool, notes: String, csvGroups: String) async
    {
        Task{
            var exerSet = await Read()
            let groups = csvGroups
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            let index = exerSet.ExerItems.firstIndex(where: { $0.id == id})
            if (index == nil)
            {
                let item = ExerItem(Name: name, Notes: notes, PerSide: perSide, Duration: duration, Groups: groups)
                exerSet.ExerItems.append(item)
            }
            else
            {
                exerSet.ExerItems[index!].Name = name
                exerSet.ExerItems[index!].PerSide = perSide
                exerSet.ExerItems[index!].Duration = duration
                exerSet.ExerItems[index!].Notes = notes
                exerSet.ExerItems[index!].Groups = groups
            }

            await SaveAsync(exerSet)
        }
    }
    static func ToggleExerciseGroup(exerciseId: UUID, group: String) async {
        var exerSet = await Read()
        exerSet.ToggleExerciseGroup(exerciseId: exerciseId, group: group)
        await SaveAsync(exerSet)
    }
    static func RemoveGroup(_ group: String) async {
        var exerSet = await Read()
        exerSet.RemoveGroup(group)
        await SaveAsync(exerSet)
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
        guard let userID = IOPAws.getUserID() else {
            print("Don't save without userID")
            return
        }
        do {
            let jsonData = try JSONEncoder().encode(exerSet)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try await ApiService.shared.write(userId: userID, json: jsonString)
            }
        } catch {
            print("Error saving: \(error)")
        }
    }
}
