//
//  ContactLensWidget.swift
//  ContactLensWidget
//
//  Created by Dan Valentin Nichita on 18/04/2026.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LensEntry {
        LensEntry(date: Date(), data: WidgetData.placeholder())
    }

    func getSnapshot(in context: Context, completion: @escaping (LensEntry) -> ()) {
        let entry = LensEntry(date: Date(), data: fetchWidgetData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LensEntry>) -> ()) {
        let data = fetchWidgetData()
        let currentDate = Date()
        
        // Update at midnight
        let calendar = Calendar.current
        guard let nextMidnight = calendar.nextDate(after: currentDate, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) else {
            completion(Timeline(entries: [], policy: .atEnd))
            return
        }
        
        let entry = LensEntry(date: currentDate, data: data)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

struct LensEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct WidgetData {
    var daysLeft: Int
    var progress: Double
    var theme: AppTheme
    var hasActiveLenses: Bool
    
    var dropsDaysLeft: Int
    var dropsProgress: Double
    var cleanerDaysLeft: Int
    var cleanerProgress: Double
    var caseDaysLeft: Int
    var caseProgress: Double
    
    static func placeholder() -> WidgetData {
        WidgetData(daysLeft: 0, progress: 0, theme: .defaultBlue, hasActiveLenses: true, dropsDaysLeft: 45, dropsProgress: 0.5, cleanerDaysLeft: 30, cleanerProgress: 0.3, caseDaysLeft: 14, caseProgress: 0.1)
    }
}

func fetchWidgetData() -> WidgetData {
    let appGroupID = "group.io.github.danvalentin-nichita.ContactLensTracker"
    guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
        return WidgetData.placeholder()
    }
    let storeURL = appGroupURL.appendingPathComponent("ContactLensTracker.sqlite")
    
    let container = NSPersistentContainer(name: "ContactLensTracker")
    container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
    
    var loaded = true
    let semaphore = DispatchSemaphore(value: 0)
    container.loadPersistentStores { _, error in
        if error != nil { loaded = false }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 2.0)
    
    guard loaded else { return WidgetData.placeholder() }
    
    let context = container.viewContext
    let request = NSFetchRequest<NSManagedObject>(entityName: "LensConfig")
    request.fetchLimit = 1
    
    guard let config = try? context.fetch(request).first else {
        return WidgetData.placeholder()
    }
    
    let startDate = config.value(forKey: "currentPairStartDate") as? Date
    let duration = config.value(forKey: "durationInDays") as? Int16 ?? 14
    let themeStr = config.value(forKey: "theme") as? String ?? "Default Blue"
    let theme = AppTheme(rawValue: themeStr) ?? .defaultBlue
    
    let isActive = startDate != nil
    let calendar = Calendar.current
    let startOfCurrent = calendar.startOfDay(for: startDate ?? Date())
    let startOfToday = calendar.startOfDay(for: Date())
    let daysElapsed = calendar.dateComponents([.day], from: startOfCurrent, to: startOfToday).day ?? 0
    let daysLeft = isActive ? max(0, Int(duration) - daysElapsed) : 0
    let progress = isActive ? (1.0 - (Double(daysElapsed) / Double(max(duration, 1)))) : 0.0
    
    func getAccessory(startKey: String, durKey: String) -> (Int, Double) {
        let aStart = config.value(forKey: startKey) as? Date
        let aDur = config.value(forKey: durKey) as? Int16 ?? 0
        if let st = aStart, aDur > 0 {
            let startD = calendar.startOfDay(for: st)
            let elapsed = calendar.dateComponents([.day], from: startD, to: startOfToday).day ?? 0
            let left = max(0, Int(aDur) - elapsed)
            let prog = 1.0 - (Double(elapsed) / Double(aDur))
            return (left, prog)
        }
        return (0, 0.0)
    }
    
    let drops = getAccessory(startKey: "eyeDropsStartDate", durKey: "eyeDropsDuration")
    let cleaner = getAccessory(startKey: "cleanerStartDate", durKey: "cleanerDuration")
    let lensCase = getAccessory(startKey: "caseStartDate", durKey: "caseDuration")
    
    return WidgetData(daysLeft: daysLeft, progress: progress, theme: theme, hasActiveLenses: isActive, dropsDaysLeft: drops.0, dropsProgress: drops.1, cleanerDaysLeft: cleaner.0, cleanerProgress: cleaner.1, caseDaysLeft: lensCase.0, caseProgress: lensCase.1)
}

struct ContactLensWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockscreenWidgetView(data: entry.data)
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Widget Views

struct LockscreenWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.3), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(data.progress, 0.0), 1.0)))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(data.daysLeft) days left")
                    .font(.headline)
                    .widgetAccentable()
                Text("Contacts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct SmallWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        ZStack {
            if !data.hasActiveLenses {
                Text("No active lenses")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 16)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(data.progress, 0.0), 1.0)))
                    .stroke(data.theme.gradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: data.progress)
                
                VStack(spacing: 2) {
                    Text("\(data.daysLeft)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Days Left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct MediumWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 24) {
            // Main Contacts
            ZStack {
                if !data.hasActiveLenses {
                    Text("No lenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 16)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(max(data.progress, 0.0), 1.0)))
                        .stroke(data.theme.gradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(data.daysLeft)")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                        Text("Days Left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 120, height: 120)
            
            // Accessories
            VStack(alignment: .leading, spacing: 16) {
                AccessoryRow(icon: "drop.fill", title: "Drops", days: data.dropsDaysLeft, progress: data.dropsProgress, theme: data.theme)
                AccessoryRow(icon: "sparkles", title: "Cleaner", days: data.cleanerDaysLeft, progress: data.cleanerProgress, theme: data.theme)
                AccessoryRow(icon: "shippingbox.fill", title: "Case", days: data.caseDaysLeft, progress: data.caseProgress, theme: data.theme)
            }
            
        }
    }
}

struct AccessoryRow: View {
    let icon: String
    let title: String
    let days: Int
    let progress: Double
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 18)
            
            Text(title)
                .font(.caption)
                .bold()
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(days)d")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle().stroke(Color.gray.opacity(0.3), lineWidth: 4)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                    .stroke(theme.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 20, height: 20)
        }
    }
}

// MARK: - Widget Definition

struct ContactLensWidget: Widget {
    let kind: String = "ContactLensWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ContactLensWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                ContactLensWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(UIColor.systemBackground))
            }
        }
        .configurationDisplayName("Lens Tracker")
        .description("Track your contact lenses and accessories")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    ContactLensWidget()
} timeline: {
    LensEntry(date: .now, data: WidgetData.placeholder())
}

#Preview(as: .systemMedium) {
    ContactLensWidget()
} timeline: {
    LensEntry(date: .now, data: WidgetData.placeholder())
}

#Preview(as: .accessoryRectangular) {
    ContactLensWidget()
} timeline: {
    LensEntry(date: .now, data: WidgetData.placeholder())
}
