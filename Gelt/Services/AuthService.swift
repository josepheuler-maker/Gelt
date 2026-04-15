import Combine
import LocalAuthentication
import SwiftUI

// ═══════════════════════════════════════════════════
//  GELT — Biometric Auth (Face ID / Touch ID / PIN)
// ═══════════════════════════════════════════════════

@MainActor
class AuthService: ObservableObject {
    @Published var isUnlocked = false
    @Published var showPINEntry = false
    @Published var authError: String?
    
    // Stored PIN (in production, use Keychain)
    private var storedPIN: String {
        get { UserDefaults.standard.string(forKey: "gelt_pin") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "gelt_pin") }
    }
    
    var authEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "gelt_auth_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "gelt_auth_enabled"); objectWillChange.send() }
    }
    
    var autoLockSeconds: Int {
        get { UserDefaults.standard.object(forKey: "gelt_auto_lock_seconds") as? Int ?? 60 }
        set { UserDefaults.standard.set(newValue, forKey: "gelt_auto_lock_seconds"); objectWillChange.send() }
    }
    
    private var lastActiveDate: Date?
    
    var hasPIN: Bool { !storedPIN.isEmpty }
    
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }
    
    enum BiometricType {
        case faceID, touchID, none
        
        var label: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .none: return "Passcode"
            }
        }
        
        var icon: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .none: return "lock.fill"
            }
        }
    }
    
    // ─── Authenticate ───────────────────────────────
    func authenticate() {
        guard authEnabled else {
            isUnlocked = true
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Gelt"
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            self.isUnlocked = true
                        }
                        self.authError = nil
                    } else {
                        // Biometric failed — offer PIN
                        if self.hasPIN {
                            self.showPINEntry = true
                        } else {
                            self.authError = "Authentication failed"
                        }
                    }
                }
            }
        } else if hasPIN {
            showPINEntry = true
        } else {
            // No biometrics, no PIN — just unlock
            isUnlocked = true
        }
    }
    
    // ─── PIN ────────────────────────────────────────
    func setPIN(_ pin: String) {
        storedPIN = pin
    }
    
    func verifyPIN(_ pin: String) -> Bool {
        if pin == storedPIN {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                isUnlocked = true
            }
            showPINEntry = false
            authError = nil
            return true
        }
        authError = "Incorrect PIN"
        return false
    }
    
    func removePIN() {
        storedPIN = ""
    }
    
    // ─── Auto-lock on background ────────────────────
    func appWillResignActive() {
        lastActiveDate = Date()
    }
    
    func appDidBecomeActive() {
        guard authEnabled, isUnlocked else { return }
        guard let last = lastActiveDate else { return }
        
        let elapsed = Date().timeIntervalSince(last)
        if elapsed > Double(autoLockSeconds) {
            withAnimation {
                isUnlocked = false
            }
        }
    }
    
    func lock() {
        withAnimation {
            isUnlocked = false
        }
    }
}
