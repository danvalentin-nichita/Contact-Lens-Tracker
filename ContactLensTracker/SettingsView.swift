import SwiftUI
import CoreData

struct SettingsView: View {
    @EnvironmentObject var lensManager: LensManager
    
    @State private var isAutoRenewEnabled: Bool = false
    @State private var nextCheckupDate: Date = Date()
    @State private var selectedTheme: AppTheme = .defaultBlue
    @State private var showingAutoRenewWarning = false
    @State private var showingNukeWarning = false
    @State private var showingPaywall = false
    
    @State private var eyeDropsDuration: Int16 = 0
    @State private var cleanerDuration: Int16 = 0
    @State private var caseDuration: Int16 = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subscription Sandbox (Testing)")) {
                    Toggle("Pro Active 👑", isOn: Binding(
                        get: { lensManager.isSubscribed },
                        set: { newValue in
                            lensManager.isSubscribed = newValue
                            if !newValue {
                                if let config = lensManager.config {
                                    config.theme = AppTheme.defaultBlue.rawValue
                                    lensManager.save()
                                    selectedTheme = .defaultBlue
                                }
                            }
                        }
                    ))
                }

                Section(header: Text("Subscription")) {
                    if lensManager.isSubscribed {
                        HStack {
                            Label("Premium Status", systemImage: "crown.fill")
                                .foregroundColor(.yellow)
                            Spacer()
                            Text("Active Pro")
                                .bold()
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: { showingPaywall = true }) {
                            HStack {
                                Label("Upgrade to Premium", systemImage: "sparkles")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Health")) {
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
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Theme")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(AppTheme.allCases, id: \.self) { theme in
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(theme.gradient)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedTheme == theme ? Color.blue : Color.clear, lineWidth: 3)
                                                    .padding(-4)
                                            )
                                            .overlay(
                                                Group {
                                                    if theme != .defaultBlue && !lensManager.isSubscribed {
                                                        Image(systemName: "lock.fill")
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.white)
                                                            .padding(4)
                                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                                            .offset(x: 14, y: 14)
                                                    }
                                                }
                                            )
                                        
                                        Text(theme.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(selectedTheme == theme ? .primary : .secondary)
                                            .lineLimit(1)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if theme != .defaultBlue && !lensManager.isSubscribed {
                                            showingPaywall = true
                                        } else {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedTheme = theme
                                                saveSettings()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 8)
                    .listRowInsets(EdgeInsets())
                }
                
                Section(header: Text("Accessory Durations (Days)")) {
                    NavigationLink(destination: DurationPickerView(title: "Eye Drops", selection: $eyeDropsDuration, onSave: saveSettings)) {
                        HStack {
                            Text("Eye Drops")
                            Spacer()
                            Text("\(eyeDropsDuration)")
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink(destination: DurationPickerView(title: "Lens Cleaner", selection: $cleanerDuration, onSave: saveSettings)) {
                        HStack {
                            Text("Lens Cleaner")
                            Spacer()
                            Text("\(cleanerDuration)")
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink(destination: DurationPickerView(title: "Contact Case", selection: $caseDuration, onSave: saveSettings)) {
                        HStack {
                            Text("Contact Case")
                            Spacer()
                            Text("\(caseDuration)")
                                .foregroundColor(.secondary)
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
            .sheet(isPresented: $showingPaywall) {
                SubscriptionView()
                    .environmentObject(lensManager)
            }
            .onAppear {
                loadSettings()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func loadSettings() {
        if let config = lensManager.config {
            isAutoRenewEnabled = config.isAutoRenewEnabled
            nextCheckupDate = config.nextCheckupDate ?? Date()
            
            let themeStr = config.theme ?? "Default Blue"
            var theme = AppTheme(rawValue: themeStr) ?? .defaultBlue
            if theme != .defaultBlue && !lensManager.isSubscribed {
                theme = .defaultBlue
                config.theme = AppTheme.defaultBlue.rawValue
                lensManager.save()
            }
            selectedTheme = theme
            showingAutoRenewWarning = isAutoRenewEnabled
            
            eyeDropsDuration = config.eyeDropsDuration
            cleanerDuration = config.cleanerDuration
            caseDuration = config.caseDuration
        }
    }
    
    private func saveSettings() {
        if let config = lensManager.config {
            config.isAutoRenewEnabled = isAutoRenewEnabled
            config.nextCheckupDate = nextCheckupDate
            config.theme = selectedTheme.rawValue
            
            config.eyeDropsDuration = eyeDropsDuration
            config.cleanerDuration = cleanerDuration
            config.caseDuration = caseDuration
            
            lensManager.save()
        }
    }
}

struct DurationPickerView: View {
    let title: String
    @Binding var selection: Int16
    var onSave: () -> Void
    
    var body: some View {
        Form {
            Section {
                Picker(title, selection: $selection) {
                    ForEach(1...999, id: \.self) { days in
                        Text("\(days) Days").tag(Int16(days))
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
            }
        }
        .navigationTitle(title)
        .onDisappear {
            onSave()
        }
    }
}
