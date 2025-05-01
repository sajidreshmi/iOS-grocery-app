import SwiftUI
import FirebaseCore // Make sure Firebase is imported if needed here

// AppDelegate (if you have one)
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct GroceryAppApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // State to control splash screen visibility
    @State private var isActive: Bool = false

    var body: some Scene {
        WindowGroup {
            // Use a ZStack to overlay ContentView on SplashScreenView
            ZStack {
                if isActive {
                    ContentView() // Your main content view
                } else {
                    SplashScreenView()
                }
            }
            .onAppear {
                // Simulate a delay for the splash screen
                // You could replace this with actual loading tasks if needed
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Show splash for 2 seconds
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}