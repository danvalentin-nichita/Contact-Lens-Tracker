import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject var lensManager: LensManager
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var showingReplaceWarning = false
    @State private var showingInventoryChooser = false
    @State private var showingPrescription = false
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if let config = lensManager.config {
                    let totalPairs = lensManager.totalInventoryCount()
                    let isActive = config.currentPairStartDate != nil
                    
                    let startDateForCalc = config.currentPairStartDate ?? Date()
                    let calendar = Calendar.current
                    let startOfCurrent = calendar.startOfDay(for: startDateForCalc)
                    let startOfToday = calendar.startOfDay(for: Date())
                    let daysElapsed = calendar.dateComponents([.day], from: startOfCurrent, to: startOfToday).day ?? 0
                    
                    let daysLeft = isActive ? max(0, Int(config.durationInDays) - daysElapsed) : 0
                    let progress = isActive ? (1.0 - (Double(daysElapsed) / Double(config.durationInDays))) : 0.0
                    
                    ScrollView {
                        if verticalSizeClass == .compact {
                            // Landscape
                            HStack(spacing: 40) {
                                if isActive {
                                    progressCircle(daysLeft: daysLeft, progress: progress)
                                } else {
                                    inactiveCircle()
                                }
                                
                                VStack(spacing: 20) {
                                    Text(String(format: NSLocalizedString("pairs_remaining", comment: ""), totalPairs))
                                        .font(.headline)
                                    
                                    replaceButton(isActive: isActive, daysLeft: daysLeft, hasPairs: totalPairs > 0)
                                    
                                    accessoriesDashboard()
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                        } else {
                            // Portrait
                            VStack(spacing: 30) {
                                if isActive {
                                    progressCircle(daysLeft: daysLeft, progress: progress)
                                } else {
                                    inactiveCircle()
                                }
                                
                                Text(String(format: NSLocalizedString("pairs_remaining", comment: ""), totalPairs))
                                    .font(.headline)
                                
                                replaceButton(isActive: isActive, daysLeft: daysLeft, hasPairs: totalPairs > 0)
                                
                                accessoriesDashboard()
                                
                                Spacer()
                            }
                            .padding()
                        }
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
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
            .sheet(isPresented: $showingPrescription) {
                PrescriptionView()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddInventoryView()
                    .environmentObject(lensManager)
            }
            .navigationBarItems(trailing: Button(action: {
                showingPrescription = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "eyeglasses")
                    Text("Prescription")
                }
            })
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
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let strokeWidth = size * 0.06
            let themeStr = lensManager.config?.theme ?? "Default Blue"
            let theme = AppTheme(rawValue: themeStr) ?? .defaultBlue
            
            ZStack {
                Circle()
                    .stroke(lineWidth: strokeWidth)
                    .opacity(0.3)
                    .foregroundColor(Color.blue)
                
                if #available(iOS 26.0, *) {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(theme.gradient)
                        .shadow(color: theme.shadowColor, radius: size * 0.03, x: 0, y: size * 0.015)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: progress)
                } else {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(theme.gradient)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: progress)
                }
                
                VStack(spacing: size * 0.02) {
                    Text("\(daysLeft)")
                        .font(.system(size: size * 0.25, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("Days Left")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                .padding(strokeWidth * 1.5)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .padding()
    }
    
    @ViewBuilder
    func replaceButton(isActive: Bool, daysLeft: Int, hasPairs: Bool) -> some View {
        if hasPairs {
            Button(action: {
                if isActive && daysLeft > 0 {
                    showingReplaceWarning = true
                } else {
                    handleReplace()
                }
            }) {
                Text(isActive ? LocalizedStringKey("replace_lenses") : LocalizedStringKey("start_lenses"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        } else {
            Button(action: {
                showingAddSheet = true
            }) {
                Text(LocalizedStringKey("add_contact_lenses"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    func inactiveCircle() -> some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let strokeWidth = size * 0.06
            
            ZStack {
                Circle()
                    .stroke(lineWidth: strokeWidth)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                VStack(spacing: size * 0.02) {
                    Text("No Active\nLenses")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(strokeWidth * 1.5)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .padding()
    }
    
    @ViewBuilder
    func accessoriesDashboard() -> some View {
        VStack(spacing: 12) {
            AccessoryCard(type: .eyeDrops)
            AccessoryCard(type: .cleaner)
            AccessoryCard(type: .lensCase)
        }
        .padding(.top, 10)
    }
}

struct AccessoryCard: View {
    @EnvironmentObject var lensManager: LensManager
    let type: LensManager.AccessoryType
    
    var iconName: String {
        switch type {
        case .eyeDrops: return "drop.fill"
        case .cleaner: return "sparkles"
        case .lensCase: return "shippingbox.fill"
        }
    }
    
    var body: some View {
        let status = lensManager.getAccessoryStatus(for: type)
        let inventoryCount = lensManager.getAccessoryCount(for: type)
        
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(type.rawValue))
                    .font(.headline)
                Text(String(format: NSLocalizedString("in_inventory", comment: ""), inventoryCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if status.duration > 0 {
                if status.isActive {
                    HStack(spacing: 10) {
                        Text(String(format: NSLocalizedString("days_left", comment: ""), status.daysLeft))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        smallProgressCircle(progress: status.progress)
                    }
                } else {
                    Button(LocalizedStringKey("start_accessory")) {
                        lensManager.startAccessory(type)
                    }
                    .font(.subheadline)
                    .buttonStyle(.bordered)
                }
            } else {
                Text(LocalizedStringKey("not_set"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func smallProgressCircle(progress: Double) -> some View {
        let size: CGFloat = 24
        let strokeWidth: CGFloat = 3
        let themeStr = lensManager.config?.theme ?? "Default Blue"
        let theme = AppTheme(rawValue: themeStr) ?? .defaultBlue
        
        ZStack {
            Circle()
                .stroke(lineWidth: strokeWidth)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                .foregroundStyle(theme.gradient)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
        .frame(width: size, height: size)
    }
}
