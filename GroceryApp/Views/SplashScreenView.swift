import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Optional: Set a background color if needed
            // Color.yourBackgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                // Use the name of your App Icon asset here
                // Make sure you have an icon named "AppIcon" in your Assets.xcassets
                Image("AppIcon") // <-- This line tries to load the image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120) // Adjust size as needed

                // Optional: Add a loading text or indicator
                // Text("Loading...")
                //     .font(.title2)
                //     .padding(.top)
            }
        }
    }
}

// Optional: Add a preview provider
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}