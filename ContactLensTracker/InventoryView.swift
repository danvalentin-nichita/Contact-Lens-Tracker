import SwiftUI
import CoreData

struct InventoryView: View {
    @EnvironmentObject var lensManager: LensManager
    @State private var showingAddSheet = false
    @State private var showingPaywall = false
    @State private var isEditing = false
    @State private var localEdits: [UUID: Int16] = [:]
    @State private var localAccessoryEdits: [LensManager.AccessoryType: Int16] = [:]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Lenses")) {
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
                
                Section(header: Text("Accessories")) {
                    if lensManager.isSubscribed {
                        if let config = lensManager.config {
                            AccessoryRow(type: .eyeDrops, count: config.eyeDropsCount, isEditing: isEditing, localAccessoryEdits: $localAccessoryEdits)
                            AccessoryRow(type: .cleaner, count: config.cleanerCount, isEditing: isEditing, localAccessoryEdits: $localAccessoryEdits)
                            AccessoryRow(type: .lensCase, count: config.caseCount, isEditing: isEditing, localAccessoryEdits: $localAccessoryEdits)
                        }
                    } else {
                        Button(action: { showingPaywall = true }) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Accessory Tracking (Pro)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    Text("Track Eye Drops, Cleaners, and Cases")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
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
            .sheet(isPresented: $showingPaywall) {
                SubscriptionView()
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
        
        localAccessoryEdits.removeAll()
        if let config = lensManager.config {
            localAccessoryEdits[.eyeDrops] = config.eyeDropsCount
            localAccessoryEdits[.cleaner] = config.cleanerCount
            localAccessoryEdits[.lensCase] = config.caseCount
        }

        // Force state update synchronously
        withAnimation {
            isEditing = true
        }
    }

    private func cancelEditing() {
        localEdits.removeAll()
        localAccessoryEdits.removeAll()
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
            if let config = lensManager.config {
                if let v = localAccessoryEdits[.eyeDrops] { config.eyeDropsCount = v }
                if let v = localAccessoryEdits[.cleaner] { config.cleanerCount = v }
                if let v = localAccessoryEdits[.lensCase] { config.caseCount = v }
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
    @State private var showingPaywall = false
    
    let itemTypes = ["Contact Lenses", "Eye Drops", "Contact Case", "Lens Cleaner"]
    @State private var selectedItemType: String = "Contact Lenses"
    
    @State private var amountToAdd: Int = 1
    
    @State private var customType: String = ""
    let lensTypeOptions = ["Daily", "Bi-Weekly", "Monthly", "Custom"]
    @State private var selectedLensType: String = "Monthly"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Info")) {
                    if #available(iOS 17.0, *) {
                        Picker("What to Add", selection: $selectedItemType) {
                            ForEach(itemTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: selectedItemType) { _, newValue in
                            if newValue != "Contact Lenses" && !lensManager.isSubscribed {
                                showingPaywall = true
                                selectedItemType = "Contact Lenses"
                            }
                        }
                    } else {
                        Picker("What to Add", selection: $selectedItemType) {
                            ForEach(itemTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: selectedItemType) { newValue in
                            if newValue != "Contact Lenses" && !lensManager.isSubscribed {
                                showingPaywall = true
                                selectedItemType = "Contact Lenses"
                            }
                        }
                    }
                    
                    if selectedItemType == "Contact Lenses" {
                        Picker("Lens Type", selection: $selectedLensType) {
                            ForEach(lensTypeOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        
                        if selectedLensType == "Custom" {
                            TextField("Enter lens type", text: $customType)
                        }
                    }
                }
                
                Section(header: Text("Quantity")) {
                    Picker("Quantity", selection: $amountToAdd) {
                        ForEach(1...100, id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
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
        .sheet(isPresented: $showingPaywall) {
            SubscriptionView()
                .environmentObject(lensManager)
        }
    }
    
    private func saveInventory() {
        if selectedItemType == "Contact Lenses" {
            let finalType = selectedLensType == "Custom" ? customType : selectedLensType
            if finalType.isEmpty { return }
            
            if let existing = lensManager.inventory.first(where: { $0.lensType == finalType }) {
                existing.pairsCount += Int16(amountToAdd)
            } else if let context = lensManager.config?.managedObjectContext {
                let newItem = LensInventory(context: context)
                newItem.id = UUID()
                newItem.lensType = finalType
                newItem.pairsCount = Int16(amountToAdd)
            }
        } else {
            // Accessories
            guard lensManager.isSubscribed else { return }
            if selectedItemType == "Eye Drops" {
                lensManager.addAccessory(.eyeDrops, count: amountToAdd)
            } else if selectedItemType == "Lens Cleaner" {
                lensManager.addAccessory(.cleaner, count: amountToAdd)
            } else if selectedItemType == "Contact Case" {
                lensManager.addAccessory(.lensCase, count: amountToAdd)
            }
        }
        lensManager.save()
    }
}

struct AccessoryRow: View {
    let type: LensManager.AccessoryType
    let count: Int16
    var isEditing: Bool
    @Binding var localAccessoryEdits: [LensManager.AccessoryType: Int16]

    var body: some View {
        HStack {
            Text(type.rawValue)
            Spacer()
            if isEditing {
                HStack(spacing: 12) {
                    Button(action: {
                        let current = localAccessoryEdits[type] ?? count
                        if current > 0 {
                            localAccessoryEdits[type] = current - 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(localAccessoryEdits[type] ?? count)")
                        .fontWeight(.bold)
                        .frame(minWidth: 30, alignment: .center)
                    
                    Button(action: {
                        let current = localAccessoryEdits[type] ?? count
                        if current < 999 {
                            localAccessoryEdits[type] = current + 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("\(count) Item(s)")
                    .fontWeight(.bold)
            }
        }
    }
}
