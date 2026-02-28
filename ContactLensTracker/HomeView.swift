import SwiftUI
import CoreData

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
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let strokeWidth = size * 0.06
            
            ZStack {
                Circle()
                    .stroke(lineWidth: strokeWidth)
                    .opacity(0.3)
                    .foregroundColor(Color.blue)
                
                if #available(iOS 26.0, *) {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(.linearGradient(colors: [.cyan, .blue, .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .cyan.opacity(0.6), radius: size * 0.03, x: 0, y: size * 0.015)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: progress)
                } else {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.blue)
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
