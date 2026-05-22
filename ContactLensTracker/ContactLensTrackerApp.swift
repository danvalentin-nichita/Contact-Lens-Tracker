import SwiftUI
import CoreData
import UserNotifications
import Combine
import WidgetKit

@main
struct ContactLensTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var lensManager = LensManager(context: PersistenceController.shared.container.viewContext)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(lensManager)
                // .onAppear {
                //     lensManager.requestNotificationPermissions()
                // }
        }
    }
}

class LensManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    @Published var config: LensConfig?
    @Published var inventory: [LensInventory] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchConfig()
        fetchInventory()
        checkAutoRenew()
    }

    func fetchConfig() {
        let request: NSFetchRequest<LensConfig> = LensConfig.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let first = results.first {
                self.config = first
            } else {
                let initialConfig = LensConfig(context: viewContext)
                initialConfig.id = UUID()
                initialConfig.totalPairs = 0
                initialConfig.durationInDays = 14
                initialConfig.currentPairStartDate = nil
                initialConfig.isAutoRenewEnabled = false
                initialConfig.prescriptionLeft = ""
                initialConfig.prescriptionRight = ""
                initialConfig.lensType = ""
                initialConfig.theme = AppTheme.defaultBlue.rawValue
                initialConfig.nextCheckupDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
                initialConfig.eyeDropsDuration = 90
                initialConfig.cleanerDuration = 90
                initialConfig.caseDuration = 90
                initialConfig.eyeDropsStartDate = nil
                initialConfig.cleanerStartDate = nil
                initialConfig.caseStartDate = nil
                initialConfig.eyeDropsCount = 0
                initialConfig.cleanerCount = 0
                initialConfig.caseCount = 0
                try viewContext.save()
                self.config = initialConfig
            }
        } catch {
            print("Failed to fetch LensConfig: \(error)")
        }
    }

    func fetchInventory() {
        let request: NSFetchRequest<LensInventory> = LensInventory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lensType", ascending: true)]
        do {
            self.inventory = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch LensInventory: \(error)")
        }
    }
    
    func nukeDatabase() {
        if let config = config {
            viewContext.delete(config)
        }
        for item in inventory {
            viewContext.delete(item)
        }
        do {
            try viewContext.save()
            self.inventory = []
            self.config = nil
            fetchConfig()
            save()
        } catch {
            print("Failed to nuke database: \(error)")
        }
    }

    func duration(for lensType: String?) -> Int? {
        guard let type = lensType?.lowercased() else { return nil }
        if type.contains("daily") { return 1 }
        if type.contains("bi-weekly") || type.contains("biweekly") { return 14 }
        if type.contains("monthly") { return 30 }
        return nil
    }

    func checkAutoRenew() {
        guard let config = config, config.isAutoRenewEnabled else { return }
        
        guard let startDate = config.currentPairStartDate else { return }
        
        let calendar = Calendar.current
        let startOfCurrent = calendar.startOfDay(for: startDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let daysElapsed = calendar.dateComponents([.day], from: startOfCurrent, to: startOfToday).day ?? 0
        
        if daysElapsed >= Int(config.durationInDays) && totalInventoryCount() > 0 {
            if let available = inventory.first(where: { $0.pairsCount > 0 }) {
                available.pairsCount -= 1
                if let newDuration = duration(for: available.lensType) {
                    config.durationInDays = Int16(newDuration)
                }
            }
            config.currentPairStartDate = Date()
            save()
        }
    }
    
    func manualRenew(using inventoryItem: LensInventory? = nil) {
        guard let config = config else { return }
        
        if let item = inventoryItem, item.pairsCount > 0 {
            item.pairsCount -= 1
            if let newDuration = duration(for: item.lensType) {
                config.durationInDays = Int16(newDuration)
            }
        } else if let available = inventory.first(where: { $0.pairsCount > 0 }) {
            available.pairsCount -= 1
            if let newDuration = duration(for: available.lensType) {
                config.durationInDays = Int16(newDuration)
            }
        }
        
        config.currentPairStartDate = Date()
        save()
    }
    
    func totalInventoryCount() -> Int {
        return inventory.reduce(0) { $0 + Int($1.pairsCount) }
    }
    
    // MARK: - Accessories Helpers
    
    enum AccessoryType: String {
        case eyeDrops = "Eye Drops"
        case cleaner = "Lens Cleaner"
        case lensCase = "Lens Case"
    }
    
    func startAccessory(_ type: AccessoryType) {
        guard let config = config else { return }
        switch type {
        case .eyeDrops:
            if config.eyeDropsCount > 0 {
                config.eyeDropsStartDate = Date()
                config.eyeDropsCount -= 1
            }
        case .cleaner:
            if config.cleanerCount > 0 {
                config.cleanerStartDate = Date()
                config.cleanerCount -= 1
            }
        case .lensCase:
            if config.caseCount > 0 {
                config.caseStartDate = Date()
                config.caseCount -= 1
            }
        }
        save()
    }
    
    func getAccessoryStatus(for type: AccessoryType) -> (daysLeft: Int, progress: Double, isActive: Bool, duration: Int) {
        guard let config = config else { return (0, 0.0, false, 0) }
        
        let startDate: Date?
        let duration: Int
        
        switch type {
        case .eyeDrops:
            startDate = config.eyeDropsStartDate
            duration = Int(config.eyeDropsDuration)
        case .cleaner:
            startDate = config.cleanerStartDate
            duration = Int(config.cleanerDuration)
        case .lensCase:
            startDate = config.caseStartDate
            duration = Int(config.caseDuration)
        }
        
        guard let start = startDate, duration > 0 else {
            return (0, 0.0, false, duration)
        }
        
        let calendar = Calendar.current
        let startOfCurrent = calendar.startOfDay(for: start)
        let startOfToday = calendar.startOfDay(for: Date())
        let daysElapsed = calendar.dateComponents([.day], from: startOfCurrent, to: startOfToday).day ?? 0
        
        let daysLeft = max(0, duration - daysElapsed)
        let progress = 1.0 - (Double(daysElapsed) / Double(duration))
        let isActive = daysLeft > 0
        
        return (daysLeft, progress, isActive, duration)
    }
    
    func getAccessoryCount(for type: AccessoryType) -> Int {
        guard let config = config else { return 0 }
        switch type {
        case .eyeDrops: return Int(config.eyeDropsCount)
        case .cleaner: return Int(config.cleanerCount)
        case .lensCase: return Int(config.caseCount)
        }
    }
    
    func addAccessory(_ type: AccessoryType, count: Int) {
        guard let config = config else { return }
        switch type {
        case .eyeDrops: config.eyeDropsCount += Int16(count)
        case .cleaner: config.cleanerCount += Int16(count)
        case .lensCase: config.caseCount += Int16(count)
        }
        save()
    }
    
    // MARK: - Prescription Helpers
    
    func getPrescriptionLeft() -> EyePrescription {
        guard let stringVal = config?.prescriptionLeft, !stringVal.isEmpty else {
            return EyePrescription()
        }
        if let data = stringVal.data(using: .utf8),
           let rx = try? JSONDecoder().decode(EyePrescription.self, from: data) {
            return rx
        }
        // Fallback for old simple string prescription
        var rx = EyePrescription()
        rx.sph = stringVal
        return rx
    }
    
    func getPrescriptionRight() -> EyePrescription {
        guard let stringVal = config?.prescriptionRight, !stringVal.isEmpty else {
            return EyePrescription()
        }
        if let data = stringVal.data(using: .utf8),
           let rx = try? JSONDecoder().decode(EyePrescription.self, from: data) {
            return rx
        }
        // Fallback for old simple string prescription
        var rx = EyePrescription()
        rx.sph = stringVal
        return rx
    }
    
    func savePrescriptions(left: EyePrescription, right: EyePrescription) {
        let encoder = JSONEncoder()
        
        if let leftData = try? encoder.encode(left),
           let leftJson = String(data: leftData, encoding: .utf8) {
            config?.prescriptionLeft = leftJson
        }
        
        if let rightData = try? encoder.encode(right),
           let rightJson = String(data: rightData, encoding: .utf8) {
            config?.prescriptionRight = rightJson
        }
        
        save()
    }
    
    func save() {
        objectWillChange.send()
        do {
            try viewContext.save()
            fetchInventory()
            WidgetCenter.shared.reloadAllTimelines()
            // scheduleNotifications()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // Notifications Logic
    /*func requestNotificationPermissions() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                self.scheduleNotifications()
            }
        }
    }
    
    func scheduleNotifications() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard let config = config, let startDate = config.currentPairStartDate else { return }
        
        // 1. Expiration Notification
        let expirationDate = Calendar.current.date(byAdding: .day, value: Int(config.durationInDays), to: startDate) ?? Date()
        scheduleNotification(title: "Contact Lens Expiring!", body: "Your current pair expires today. Time to switch!", triggerDate: expirationDate, identifier: "expiration")
        
        // 2. Low Pairs Warning
        if config.totalPairs <= 1 {
            scheduleNotification(title: "Running Low on Lenses", body: "You only have \(config.totalPairs) pair(s) left. Order more!", triggerDate: Date().addingTimeInterval(3600), identifier: "low_pairs")
        }
        
        // 3. Upcoming Checkup (1 week before)
        if let checkupDate = config.nextCheckupDate {
            let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: checkupDate) ?? Date()
            if reminderDate > Date() {
                scheduleNotification(title: "Upcoming Eye Checkup", body: "Your eye checkup is next week.", triggerDate: reminderDate, identifier: "checkup_reminder")
            }
        }
    }
    
    private func scheduleNotification(title: String, body: String, triggerDate: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Error scheduling notification: \(error)") }
        }
    }*/
}
