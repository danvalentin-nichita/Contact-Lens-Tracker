import SwiftUI

struct WheelPickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    @State private var showingPicker = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: {
                showingPicker.toggle()
            }) {
                Text(selection.isEmpty ? "Select" : selection)
                    .foregroundColor(selection.isEmpty ? .secondary : .primary)
            }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationView {
                VStack {
                    Picker(title, selection: $selection) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                }
                .navigationTitle("Select \(title)")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("Done") {
                    showingPicker = false
                })
            }
            .modifier(SheetHeightModifier())
        }
    }
}

private struct SheetHeightModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}
