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

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LensManager(context: PersistenceController.preview.container.viewContext))
}
