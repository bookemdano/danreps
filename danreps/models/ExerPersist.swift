//
//  ExerPersist.swift
//  danreps
//
//  Created by Daniel Francis on 4/27/25.
//
import Foundation
import DanSwiftLib

struct ExerPersist {
    static let _iop = IOPAws(app: "DanReps")

    static func JsonName() -> String{
        var userID = IOPAws.getUserID()
        if (userID == nil){
            userID = "Template"
        }
        return "exers\(userID!).json"
    }
    
    static func Read() async -> ExerSet{
        
        let content = await _iop.Read(dir: "Data", file: JsonName())
        if (content.isEmpty){
            return ExerSet.GetDefault()
        }
        
        let jsonString = content
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                var rv = try JSONDecoder().decode(ExerSet.self, from: jsonData)
                if (rv.Version != ExerSet.CurrentVersion) {
                    rv.UpdateVersion()
                }
                return rv
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }
        return ExerSet.GetDefault()
    }
    static func Update(id: UUID, name: String, perSide: Bool, duration: Bool, notes: String, csvGroups: String) async
    {
        Task{
            var exerSet = await Read()

            let index = exerSet.ExerItems.firstIndex(where: { $0.id == id})
            if (index == nil)
            {
                let item = ExerItem(Name: name, Notes: notes, PerSide: perSide, Duration: duration, Groups: csvGroups.components(separatedBy: ","))
                exerSet.ExerItems.append(item)
            }
            else
            {
                exerSet.ExerItems[index!].Name = name
                exerSet.ExerItems[index!].PerSide = perSide
                exerSet.ExerItems[index!].Duration = duration
                exerSet.ExerItems[index!].Notes = notes
                exerSet.ExerItems[index!].Groups = csvGroups.components(separatedBy: ",")
            }

            await SaveAsync(exerSet)
        }
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
        if (IOPAws.getUserID() == nil) {
            print("Don't save without userID")
            return
        }
        do {
            let jsonData = try JSONEncoder().encode(exerSet)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                if (await _iop.Write(dir: "Data", file: JsonName(), content: jsonString) == false){
                    print("Write failed!")
                }
            }
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
}
