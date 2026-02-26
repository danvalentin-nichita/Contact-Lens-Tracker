import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var lensManager: LensManager
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "list.clipboard.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var lensManager: LensManager
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var showingReplaceWarning = false
    @State private var showingInventoryChooser = false
    
    var body: some View {
        NavigationView {
            Group {
                if let config = lensManager.config {
                    let calendar = Calendar.current
                    let startOfCurrent = calendar.startOfDay(for: config.currentPairStartDate ?? Date())
                    let startOfToday = calendar.startOfDay(for: Date())
                    let daysElapsed = calendar.dateComponents([.day], from: startOfCurrent, to: startOfToday).day ?? 0
                    let daysLeft = max(0, Int(config.durationInDays) - daysElapsed)
                    let progress = 1.0 - (Double(daysElapsed) / Double(config.durationInDays))
                    let totalPairs = lensManager.totalInventoryCount()
                    
                    if verticalSizeClass == .compact {
                        // Landscape
                        HStack(spacing: 40) {
                            progressCircle(daysLeft: daysLeft, progress: progress)
                            
                            VStack(spacing: 20) {
                                Text("\(totalPairs) Pairs Remaining")
                                    .font(.headline)
                                
                                replaceButton(daysLeft: daysLeft, hasPairs: totalPairs > 0)
                                
                                infoDashboard(config: config)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    } else {
                        // Portrait
                        VStack(spacing: 30) {
                            progressCircle(daysLeft: daysLeft, progress: progress)
                            
                            Text("\(totalPairs) Pairs Remaining")
                                .font(.headline)
                            
                            replaceButton(daysLeft: daysLeft, hasPairs: totalPairs > 0)
                            
                            Divider().padding(.vertical)
                            
                            infoDashboard(config: config)
                            
                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Lens Tracker")
            .alert("Replace Lenses Early?", isPresented: $showingReplaceWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Replace", role: .destructive) {
                    handleReplace()
                }
            } message: {
                Text("Your current pair is still good. Are you sure you want to replace it now?")
            }
            .confirmationDialog("Choose Lens Type to Renew", isPresented: $showingInventoryChooser, titleVisibility: .visible) {
                let availableInventories = lensManager.inventory.filter { $0.pairsCount > 0 }
                ForEach(availableInventories, id: \.id) { inv in
                    Button("\(inv.lensType ?? "Unknown") (\(inv.pairsCount) left)") {
                        lensManager.manualRenew(using: inv)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func handleReplace() {
        let available = lensManager.inventory.filter { $0.pairsCount > 0 }
        if available.count == 1 {
            lensManager.manualRenew(using: available.first)
        } else if available.count > 1 {
            showingInventoryChooser = true
        } else {
            lensManager.manualRenew()
        }
    }
    
    @ViewBuilder
    func progressCircle(daysLeft: Int, progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(Color.blue)
            
            if #available(iOS 26.0, *) {
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(.linearGradient(colors: [.cyan, .blue, .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .cyan.opacity(0.6), radius: 10, x: 0, y: 5)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
            } else {
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
            }
            
            VStack(spacing: 5) {
                Text("\(daysLeft)")
                    .font(.system(size: 80, weight: .bold))
                Text("Days Left")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 350)
        .padding()
    }
    
    @ViewBuilder
    func replaceButton(daysLeft: Int, hasPairs: Bool) -> some View {
        if hasPairs {
            Button(action: {
                if daysLeft > 0 {
                    showingReplaceWarning = true
                } else {
                    handleReplace()
                }
            }) {
                Text("Replace Lenses")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        } else {
            Text("No pairs left. Add more!")
                .font(.headline)
                .foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    func infoDashboard(config: LensConfig) -> some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Prescription").font(.caption).foregroundColor(.secondary)
                Text("L: \(config.prescriptionLeft ?? "-")   R: \(config.prescriptionRight ?? "-")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("Next Checkup").font(.caption).foregroundColor(.secondary)
                if let pd = config.nextCheckupDate {
                    Text(pd, style: .date)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
                    Text("Not Set")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            // Only show type if there is exactly 1 type in inventory
            if lensManager.inventory.count == 1, let type = lensManager.inventory.first?.lensType, !type.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Type").font(.caption).foregroundColor(.secondary)
                    Text(type)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

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
                        Button( action: { saveChanges() }) {
                            Image(systemName: "checkmark")
                        }
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
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveInventory()
                    dismiss()
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

struct SettingsView: View {
    @EnvironmentObject var lensManager: LensManager
    
    @State private var isAutoRenewEnabled: Bool = false
    @State private var prescriptionLeft: String = ""
    @State private var prescriptionRight: String = ""
    @State private var nextCheckupDate: Date = Date()
    @State private var showingAutoRenewWarning = false
    @State private var showingNukeWarning = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prescription & Health")) {
                    HStack {
                        Text("Left Eye (OS)")
                        Spacer()
                        TextField("-2.00", text: $prescriptionLeft)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .onChange(of: prescriptionLeft) { _ in saveSettings() }
                    }
                    HStack {
                        Text("Right Eye (OD)")
                        Spacer()
                        TextField("-2.00", text: $prescriptionRight)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .onChange(of: prescriptionRight) { _ in saveSettings() }
                    }
                    DatePicker("Next Checkup", selection: $nextCheckupDate, displayedComponents: .date)
                        .onChange(of: nextCheckupDate) { _ in saveSettings() }
                }

                Section(header: Text("Preferences"), footer: Text(showingAutoRenewWarning ? "Warning: Pairs will be deducted automatically without confirmation when the duration expires." : "")) {
                    if #available(iOS 17.0, *) {
                        Toggle("Auto-Renew Pairs", isOn: $isAutoRenewEnabled)
                            .onChange(of: isAutoRenewEnabled) { _, newValue in
                                showingAutoRenewWarning = newValue
                                saveSettings()
                            }
                    } else {
                        Toggle("Auto-Renew Pairs", isOn: $isAutoRenewEnabled)
                            .onChange(of: isAutoRenewEnabled) { newValue in
                                showingAutoRenewWarning = newValue
                                saveSettings()
                            }
                    }
                }
                
                Section {
                    Button("Reset Current Pair Start Date") {
                        lensManager.config?.currentPairStartDate = Date()
                        lensManager.save()
                    }
                    .foregroundColor(.blue)
                }

                Section(header: Text("Danger Zone")) {
                    Button(role: .destructive, action: {
                        showingNukeWarning = true
                    }) {
                        Label("Nuke Database", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                    .alert("Are you absolutely sure?", isPresented: $showingNukeWarning) {
                        Button("Cancel", role: .cancel) { }
                        Button("Nuke It All", role: .destructive) {
                            lensManager.nukeDatabase()
                            // Reload local states after clean slate
                            loadSettings()
                        }
                    } message: {
                        Text("This will delete all your settings, prescription data, and inventory. This cannot be undone.")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func loadSettings() {
        if let config = lensManager.config {
            isAutoRenewEnabled = config.isAutoRenewEnabled
            prescriptionLeft = config.prescriptionLeft ?? ""
            prescriptionRight = config.prescriptionRight ?? ""
            nextCheckupDate = config.nextCheckupDate ?? Date()
            showingAutoRenewWarning = isAutoRenewEnabled
        }
    }
    
    private func saveSettings() {
        if let config = lensManager.config {
            config.isAutoRenewEnabled = isAutoRenewEnabled
            config.prescriptionLeft = prescriptionLeft
            config.prescriptionRight = prescriptionRight
            config.nextCheckupDate = nextCheckupDate
            lensManager.save()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LensManager(context: PersistenceController.preview.container.viewContext))
}
