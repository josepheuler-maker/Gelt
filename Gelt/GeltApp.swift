import SwiftUI
import Combine

// ═══════════════════════════════════════════════════
//  G E L T  ₪  — Black & Gold Edition
// ═══════════════════════════════════════════════════

@main
struct GeltApp: App {
    @StateObject private var store = DataStore()
    @StateObject private var auth = AuthService()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(auth)
                .preferredColorScheme(.dark)
                .background(Theme.bg)
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 750)
        #endif
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: auth.appWillResignActive()
            case .active: auth.appDidBecomeActive()
            default: break
            }
        }
    }
}

// ─── Notification for keyboard shortcuts ────────────
extension Notification.Name {
    static let geltNewTransaction = Notification.Name("geltNewTransaction")
}

// ═══ Root View — Lock Screen Gate ═══════════════════

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    
    var body: some View {
        #if os(macOS)
        // macOS: skip lock screen, go straight to app
        ContentView()
            .frame(minWidth: 800, minHeight: 600)
        #else
        ZStack {
            ContentView()
                .opacity(auth.isUnlocked ? 1 : 0)
                .allowsHitTesting(auth.isUnlocked)
            
            if !auth.isUnlocked {
                LockScreenView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: auth.isUnlocked)
        .onAppear { auth.authenticate() }
        #endif
    }
}

// ═══ Lock Screen ════════════════════════════════════

struct LockScreenView: View {
    @EnvironmentObject var auth: AuthService
    @State private var pinInput = ""
    @State private var shake = false
    @State private var showingPIN = false
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text("₪")
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .foregroundColor(Theme.gold)
                
                Text("GELT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(6)
                    .foregroundColor(Theme.faint)
                    .padding(.top, 8)
                
                Spacer().frame(height: 40)
                
                if showingPIN || auth.showPINEntry {
                    pinEntryView
                } else {
                    biometricView
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var biometricView: some View {
        VStack(spacing: 16) {
            Button { auth.authenticate() } label: {
                VStack(spacing: 12) {
                    Image(systemName: auth.biometricType.icon)
                        .font(.system(size: 32))
                        .foregroundColor(Theme.gold)
                    Text("Tap to unlock")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.dim)
                }
                .frame(width: 110, height: 110)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.gold.opacity(0.2), lineWidth: 1))
            }
            
            if auth.hasPIN {
                Button { showingPIN = true } label: {
                    Text("Use PIN instead").font(.system(size: 12)).foregroundColor(Theme.faint)
                }
            }
            
            if let error = auth.authError {
                Text(error).font(.system(size: 12)).foregroundColor(Theme.red)
            }
        }
    }
    
    private var pinEntryView: some View {
        VStack(spacing: 20) {
            Text("Enter PIN")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.cream)
            
            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < pinInput.count ? Theme.gold : Theme.cardBorder)
                        .frame(width: 14, height: 14)
                }
            }
            .modifier(ShakeEffect(shakes: shake ? 2 : 0))
            
            if let error = auth.authError {
                Text(error).font(.system(size: 12)).foregroundColor(Theme.red)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(72), spacing: 16), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { num in
                    PINPadButton(label: "\(num)") { appendPIN("\(num)") }
                }
                PINPadButton(label: "", disabled: true) { }
                PINPadButton(label: "0") { appendPIN("0") }
                PINPadButton(label: "⌫", isDelete: true) {
                    if !pinInput.isEmpty { pinInput.removeLast() }
                }
            }
            
            if auth.biometricType != .none {
                Button {
                    showingPIN = false
                    pinInput = ""
                    auth.authenticate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: auth.biometricType.icon)
                        Text("Use \(auth.biometricType.label)")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.gold)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func appendPIN(_ digit: String) {
        guard pinInput.count < 4 else { return }
        pinInput += digit
        Haptics.selection()
        if pinInput.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if auth.verifyPIN(pinInput) {
                    Haptics.success()
                } else {
                    Haptics.error()
                    withAnimation(.default) { shake = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        shake = false
                        pinInput = ""
                    }
                }
            }
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 2), y: 0))
    }
}

// ═══ Content View — Platform Adaptive ═══════════════

struct ContentView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var sizeClass
    #endif
    
    var body: some View {
        Group {
            #if os(macOS)
            MacLayout()
            #else
            if sizeClass == .regular {
                // iPad
                MacLayout()
            } else {
                // iPhone
                PhoneLayout()
            }
            #endif
        }
    }
}

// ═══ iPhone — Tab Bar ═══════════════════════════════

struct PhoneLayout: View {
    @State private var selectedTab = 0
    
    init() {
        #if os(iOS)
        // Style tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.bg)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.faint)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.faint)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.gold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.gold)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            AccountsView()
                .tabItem {
                    Image(systemName: "wallet.pass.fill")
                    Text("Accounts")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .tint(Theme.gold)
    }
}

// ═══ iPad / Mac — Sidebar ══════════════════════════

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case accounts = "Accounts"
    case settings = "Settings"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .accounts: return "wallet.pass.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MacLayout: View {
    @State private var selected: SidebarItem? = .home
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selected) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("₪ Gelt")
            .tint(Theme.gold)
        } detail: {
            Group {
                switch selected {
                case .home: HomeView()
                case .accounts: AccountsView()
                case .settings: SettingsView()
                case .none: HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg)
        }
        .tint(Theme.gold)
        .background(Theme.bg)
    }
}

// ═══ Haptics ═══════════════════════════════════════

struct Haptics {
    #if os(iOS)
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    #else
    static func tap() {}
    static func success() {}
    static func warning() {}
    static func error() {}
    static func selection() {}
    #endif
}
