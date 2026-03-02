import SwiftUI
import CoreData

struct InventoryView: View {
    @EnvironmentObject var lensManager: LensManager
    @State private var showingAddSheet = false
    @State private var isEditing = false
    @State private var localEdits: [UUID: Int16] = [:]

    var body: some View {
        NavigationView {
            List {
                if lensManager.inventory.isEmpty {
                    Text("No inventory tracked yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(lensManager.inventory, id: \.id) { item in
                        InventoryRow(item: item, isEditing: isEditing, localEdits: $localEdits)
                    }
                    .onDelete(perform: deleteInventory)
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button(action: { cancelEditing() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        }
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        if #available(iOS 26, *) {
                            Button(role: .confirm, action: {saveChanges()}) {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            Button( action: { saveChanges() }) {
                                Image(systemName: "checkmark")
                            }}
                    } else {
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .sheet(isPresented: $showingAddSheet) {
                AddInventoryView()
                    .environmentObject(lensManager)
            }
        }
        .navigationViewStyle(.stack)
    }

    private func startEditing() {
        localEdits.removeAll()
        for item in lensManager.inventory {
            if let id = item.id {
                localEdits[id] = item.pairsCount
            }
        }
        // Force state update synchronously
        withAnimation {
            isEditing = true
        }
    }

    private func cancelEditing() {
        localEdits.removeAll()
        withAnimation {
            isEditing = false
        }
    }

    private func saveChanges() {
        if let context = lensManager.config?.managedObjectContext {
            for item in lensManager.inventory {
                if let id = item.id, let newCount = localEdits[id], newCount != item.pairsCount {
                    if newCount == 0 {
                        context.delete(item)
                    } else {
                        item.pairsCount = newCount
                    }
                }
            }
            lensManager.save()
        }
        withAnimation {
            isEditing = false
        }
    }

    private func deleteInventory(offsets: IndexSet) {
        if let context = lensManager.config?.managedObjectContext {
            for index in offsets {
                let item = lensManager.inventory[index]
                if let id = item.id {
                    localEdits.removeValue(forKey: id)
                }
                context.delete(item)
            }
            lensManager.save()
        }
    }
}

struct InventoryRow: View {
    @ObservedObject var item: LensInventory
    var isEditing: Bool
    @Binding var localEdits: [UUID: Int16]

    var body: some View {
        HStack {
            Text(item.lensType ?? "Unknown")
            Spacer()
            if isEditing {
                HStack(spacing: 12) {
                    Button(action: {
                        if let id = item.id, let current = localEdits[id], current > 0 {
                            localEdits[id] = current - 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    
                    if let id = item.id, let current = localEdits[id] {
                        Text("\(current)")
                            .fontWeight(.bold)
                            .frame(minWidth: 30, alignment: .center)
                    }
                    
                    Button(action: {
                        if let id = item.id, let current = localEdits[id], current < 999 {
                            localEdits[id] = current + 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("\(item.pairsCount) Pair(s)")
                    .fontWeight(.bold)
            }
        }
    }
}

struct AddInventoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lensManager: LensManager
    
    @State private var pairsToAdd: Int = 1
    @State private var customType: String = ""
    
    let typeOptions = ["Daily", "Bi-Weekly", "Monthly", "Custom"]
    @State private var selectedType: String = "Monthly"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add Pairs")) {
                    Stepper("\(pairsToAdd) Pair(s)", value: $pairsToAdd, in: 1...100)
                }
                
                Section(header: Text("Lens Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(typeOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if selectedType == "Custom" {
                        TextField("Enter lens type", text: $customType)
                    }
                }
            }
            .navigationTitle("Add Inventory")
            .navigationBarItems(
                leading: Group {
                    if #available(iOS 26.0, *) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                        }
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                },
                trailing: Group {
                    if #available(iOS 26.0, *) {
                        Button(role:.confirm, action: {
                            saveInventory()
                            dismiss()
                        }) {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Button("Save") {
                            saveInventory()
                            dismiss()
                        }
                    }
                }
            )
        }
    }
    
    private func saveInventory() {
        let finalType = selectedType == "Custom" ? customType : selectedType
        if finalType.isEmpty { return }
        
        if let existing = lensManager.inventory.first(where: { $0.lensType == finalType }) {
            existing.pairsCount += Int16(pairsToAdd)
        } else if let context = lensManager.config?.managedObjectContext {
            let newItem = LensInventory(context: context)
            newItem.id = UUID()
            newItem.lensType = finalType
            newItem.pairsCount = Int16(pairsToAdd)
        }
        lensManager.save()
    }
}
