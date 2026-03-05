import SwiftUI
import CoreData

struct SettingsView: View {
    @EnvironmentObject var lensManager: LensManager
    
    @State private var isAutoRenewEnabled: Bool = false
    @State private var nextCheckupDate: Date = Date()
    @State private var selectedTheme: AppTheme = .defaultBlue
    @State private var showingAutoRenewWarning = false
    @State private var showingNukeWarning = false
    
    var body: some View {
        NavigationView {
            Form {
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
                                        
                                        Text(theme.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(selectedTheme == theme ? .primary : .secondary)
                                            .lineLimit(1)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTheme = theme
                                            saveSettings()
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
            nextCheckupDate = config.nextCheckupDate ?? Date()
            if let themeStr = config.theme, let theme = AppTheme(rawValue: themeStr) {
                selectedTheme = theme
            }
            showingAutoRenewWarning = isAutoRenewEnabled
        }
    }
    
    private func saveSettings() {
        if let config = lensManager.config {
            config.isAutoRenewEnabled = isAutoRenewEnabled
            config.nextCheckupDate = nextCheckupDate
            config.theme = selectedTheme.rawValue
            lensManager.save()
        }
    }
}
