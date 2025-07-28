

import SwiftUICore
import SwiftUI
import DanSwiftLib

struct AddToGroupView: View {
    @State var exerSet: ExerSet
    @State var group: String
    let _iop = IOPAws(app: "ToDone")

    var body: some View {
        NavigationStack{
            List{
                ForEach(exerSet.ExerItems.sorted{$0.Name.localizedCaseInsensitiveCompare($1.Name) == .orderedAscending}, id: \.self){ item in
                    Toggle(item.Name, isOn: Binding (
                        get: {
                            item.isInGroup(group)
                        }, set: {
                            isOn in if isOn {
                                item.addGroup(group)
                            } else {
                                item.removeGroup(group)
                            }
                            save()
                        })
                    )
                }
            }
            Spacer()
            NavigationLink(destination: ExerItemView(exerItem: ExerItem(Name: "", Notes: "", PerSide: false), history: nil)) {
                Text("New Item").bold()
            }
        }
        .navigationTitle("Add to Group")
        .refreshable {
            Refresh()
        }
        .onAppear {
            Refresh()
        }
    }


    func save()
    {
        Task{
            await ExerPersist.SaveAsync(exerSet)
            Refresh()
        }
    }
    
    func Refresh()
    {
        Task{
            exerSet.Refresh(other: await ExerPersist.Read(), date: Date());
        }
    }
}
