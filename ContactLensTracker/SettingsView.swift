import SwiftUI
import CoreData

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
