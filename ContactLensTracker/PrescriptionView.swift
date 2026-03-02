import SwiftUI

struct PrescriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lensManager: LensManager
    
    @State private var isEditing = false
    
    @State private var draftLeft: EyePrescription = EyePrescription()
    @State private var draftRight: EyePrescription = EyePrescription()
    
    @State private var hasAstigmatism = false
    @State private var hasMultifocal = false
    
    // MARK: - Options Generators
    
    let sphOptions: [String] = {
        var options: [String] = ["0.00"]
        for i in stride(from: -20.0, through: 20.0, by: 0.25) {
            if i != 0.0 {
                options.append(String(format: "%+.2f", i))
            }
        }
        return options.sorted { (a, b) -> Bool in
            let floatA = Float(a) ?? 0.0
            let floatB = Float(b) ?? 0.0
            return floatA < floatB
        }
    }()
    
    let cylOptions: [String] = {
        var options: [String] = ["0.00"]
        for i in stride(from: -10.0, through: 10.0, by: 0.25) {
            if i != 0.0 {
                options.append(String(format: "%+.2f", i))
            }
        }
        return options.sorted { (a, b) -> Bool in
            let floatA = Float(a) ?? 0.0
            let floatB = Float(b) ?? 0.0
            return floatA < floatB
        }
    }()
    
    let axisOptions: [String] = {
        return (0...180).map { String($0) }
    }()
    
    let bcOptions: [String] = {
        var options: [String] = []
        for i in stride(from: 8.0, through: 9.5, by: 0.1) {
            options.append(String(format: "%.1f", i))
        }
        return options
    }()
    
    let diaOptions: [String] = {
        var options: [String] = []
        for i in stride(from: 13.0, through: 15.0, by: 0.1) {
            options.append(String(format: "%.1f", i))
        }
        return options
    }()
    
    let addOptions: [String] = {
        var options: [String] = ["Low", "Medium", "High"]
        for i in stride(from: +0.75, through: +3.00, by: 0.25) {
            options.append(String(format: "%+.2f", i))
        }
        return options
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    HStack {
                        Text("")
                            .frame(width: 50)
                        Spacer()
                        Text("L (OS)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("R (OD)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    if isEditing {
                        eyeForm()
                    } else {
                        eyeDetails()
                    }
                }
            }
            .navigationTitle("Prescription")
            .navigationBarItems(
                leading: leadingButton,
                trailing: trailingButton
            )
            .onAppear {
                loadDrafts()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    private var leadingButton: some View {
        Button(action: {
            if isEditing {
                loadDrafts()
                isEditing = false
            } else {
                dismiss()
            }
        }) {
            if #available(iOS 26.0, *) {
                Image(systemName: "xmark")
            } else {
                Text(isEditing ? "Cancel" : "Close")
            }
        }
    }
    
    @ViewBuilder
    private var trailingButton: some View {
        if isEditing {
            if #available(iOS 26.0, *) {
                Button(role: .confirm, action: saveEditing) {
                    Image(systemName: "checkmark")
                }
            } else {
                Button("Save", action: saveEditing)
            }
        } else {
            Button(action: {
                isEditing = true
            }) {
                if #available(iOS 26.0, *) {
                    Image(systemName: "pencil")
                } else {
                    Text("Edit")
                }
            }
        }
    }
    
    private func saveEditing() {
        draftLeft.hasAstigmatism = hasAstigmatism
        draftRight.hasAstigmatism = hasAstigmatism
        draftLeft.hasMultifocal = hasMultifocal
        draftRight.hasMultifocal = hasMultifocal
        lensManager.savePrescriptions(left: draftLeft, right: draftRight)
        isEditing = false
    }
    
    private func loadDrafts() {
        draftLeft = lensManager.getPrescriptionLeft()
        draftRight = lensManager.getPrescriptionRight()
        hasAstigmatism = draftLeft.hasAstigmatism || draftRight.hasAstigmatism
        hasMultifocal = draftLeft.hasMultifocal || draftRight.hasMultifocal
    }
    
    @ViewBuilder
    private func eyeDetails() -> some View {
        dualTextRow(title: "SPH", left: draftLeft.sph, right: draftRight.sph)
        dualTextRow(title: "BC", left: draftLeft.bc, right: draftRight.bc)
        dualTextRow(title: "DIA", left: draftLeft.dia, right: draftRight.dia)
        
        if hasAstigmatism {
            dualTextRow(title: "CYL", left: draftLeft.cyl, right: draftRight.cyl)
            dualTextRow(title: "AXIS", left: draftLeft.axis, right: draftRight.axis)
        }
        
        if hasMultifocal {
            dualTextRow(title: "ADD", left: draftLeft.add, right: draftRight.add)
        }
    }
    
    @ViewBuilder
    private func dualTextRow(title: String, left: String, right: String) -> some View {
        HStack {
            Text(title).frame(width: 50, alignment: .leading)
            Spacer()
            Text(left.isEmpty ? "-" : left)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(right.isEmpty ? "-" : right)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    private func eyeForm() -> some View {
        DualWheelPickerRow(title: "SPH", leftSelection: $draftLeft.sph, rightSelection: $draftRight.sph, options: sphOptions)
        DualWheelPickerRow(title: "BC", leftSelection: $draftLeft.bc, rightSelection: $draftRight.bc, options: bcOptions)
        DualWheelPickerRow(title: "DIA", leftSelection: $draftLeft.dia, rightSelection: $draftRight.dia, options: diaOptions)
        
        Toggle("Astigmatism", isOn: $hasAstigmatism)
        if hasAstigmatism {
            DualWheelPickerRow(title: "CYL", leftSelection: $draftLeft.cyl, rightSelection: $draftRight.cyl, options: cylOptions)
            DualWheelPickerRow(title: "AXIS", leftSelection: $draftLeft.axis, rightSelection: $draftRight.axis, options: axisOptions)
        }
        
        Toggle("Multifocal", isOn: $hasMultifocal)
        if hasMultifocal {
            DualWheelPickerRow(title: "ADD", leftSelection: $draftLeft.add, rightSelection: $draftRight.add, options: addOptions)
        }
    }
}
