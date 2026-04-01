import Foundation
import SwiftUI

/// Manages the active app edition: generic (default) or sunflower (secret code activated)
class EditionManager: ObservableObject {
    static let shared = EditionManager()

    enum Edition: String {
        case generic    // 通用版（默认）
        case sunflower  // 太阳葵版（密码激活）
    }

    @AppStorage("Faraway_Edition") private var editionRaw: String = Edition.generic.rawValue
    @Published var currentEdition: Edition = .generic

    var isSunflower: Bool { currentEdition == .sunflower }

    private init() {
        currentEdition = Edition(rawValue: editionRaw) ?? .generic
    }

    /// Attempt to activate sunflower edition with a secret code. Returns true on success.
    func activate(code: String) -> Bool {
        if code == "0523" {
            editionRaw = Edition.sunflower.rawValue
            currentEdition = .sunflower
            return true
        }
        return false
    }

    /// Deactivate sunflower edition and revert to generic.
    func deactivate() {
        editionRaw = Edition.generic.rawValue
        currentEdition = .generic
    }
}
