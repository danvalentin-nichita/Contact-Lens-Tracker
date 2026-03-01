import SwiftUI

struct DualWheelPickerRow: View {
    let title: String
    @Binding var leftSelection: String
    @Binding var rightSelection: String
    let options: [String]
    
    @State private var showingLeftPicker = false
    @State private var showingRightPicker = false
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            Button(action: {
                showingLeftPicker.toggle()
            }) {
                Text(leftSelection.isEmpty ? "-" : leftSelection)
                    .foregroundColor(leftSelection.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .sheet(isPresented: $showingLeftPicker) {
                pickerSheet(title: "Left (OS) \(title)", selection: $leftSelection, isPresented: $showingLeftPicker)
            }
            
            Divider()
            
            Button(action: {
                showingRightPicker.toggle()
            }) {
                Text(rightSelection.isEmpty ? "-" : rightSelection)
                    .foregroundColor(rightSelection.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .sheet(isPresented: $showingRightPicker) {
                pickerSheet(title: "Right (OD) \(title)", selection: $rightSelection, isPresented: $showingRightPicker)
            }
        }
    }
    
    @ViewBuilder
    private func pickerSheet(title: String, selection: Binding<String>, isPresented: Binding<Bool>) -> some View {
        NavigationView {
            VStack {
                Picker(title, selection: selection) {
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
                isPresented.wrappedValue = false
            })
        }
        .modifier(SheetHeightModifier())
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
