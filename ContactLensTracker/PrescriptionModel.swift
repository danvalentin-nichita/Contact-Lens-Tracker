import Foundation

struct EyePrescription: Codable {
    var sph: String = ""
    var hasAstigmatism: Bool = false
    var cyl: String = ""
    var axis: String = ""
    var hasMultifocal: Bool = false
    var add: String = ""
    var bc: String = ""
    var dia: String = ""
}
