import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var currentPage = 0
    @State private var selectedIcon: String? = nil
    var onFinish: () -> Void
    
    private var accentColor: Color {
        appSettings.accentColor
    }
    
    let iconOptions: [(name: String, filename: String?)] = [
        ("Default", nil),
        ("Dark Blue", "icon-dark-blue"),
        ("Dark Green", "icon-dark-green"),
        ("Dark Mint", "icon-dark-mint"),
        ("Dark Orange", "icon-dark-orange"),
        ("Dark Purple", "icon-dark-purple"),
        ("Dark Red", "icon-dark-red"),
        ("Light Green", "icon-light-green"),
        ("Light Mint", "icon-light-mint"),
        ("Light Orange", "icon-light-orange"),
        ("Light Purple", "icon-light-purple"),
        ("Light Red", "icon-light-red")
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Page 1 - Welcome
                welcomeView
                    .tag(0)
                
                // Page 2 - Accent Color Selection
                accentColorView
                    .tag(1)
                
                // Page 3 - App Icon Selection
                appIconView
                    .tag(2)
                
                // Page 4 - Getting Started
                gettingStartedView
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .accentColor(accentColor)
    }
    
    
    private var welcomeView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 30) {
                Image("icon-default")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: Color(.systemGray3).opacity(0.2), radius: 6, x: 0, y: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                
                VStack(spacing: 8) {
                    Text("Welcome to TailTag")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your Digital Planespotting Logbook")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    currentPage = 1
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentColor)
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 30)
    }
    
    private var accentColorView: some View {
        VStack {
            Spacer()

            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Choose Your Style")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Pick an accent color that you like")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 65), spacing: 20)], spacing: 25) {
                    ForEach(AccentColorOption.defaultOptions) { option in
                        Button {
                            appSettings.accentColor = option.color
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 65, height: 65)
                                    .shadow(color: Color(.systemGray3).opacity(0.3), radius: 4, x: 0, y: 2)

                                if isColorSelected(option.color) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 25, height: 25)

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(option.color)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            Button {
                withAnimation {
                    currentPage = 2
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentColor)
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }

    private var appIconView: some View {
        VStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("App Icon")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Choose your preferred app icon")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 20)], spacing: 25) {
                        ForEach(iconOptions, id: \.filename) { option in
                            Button {
                                selectIcon(option.filename)
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack(alignment: .topTrailing) {
                                        iconImage(for: option.filename)
                                            .resizable()
                                            .aspectRatio(1, contentMode: .fit)
                                            .cornerRadius(16)
                                            .frame(width: 75, height: 75)
                                            .shadow(color: Color(.systemGray3).opacity(0.3), radius: 3, x: 0, y: 2)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedIcon == option.filename ? accentColor : Color.clear, lineWidth: 3)
                                            )
                                        
                                        if selectedIcon == option.filename {
                                            ZStack {
                                                Circle()
                                                    .fill(accentColor)
                                                    .frame(width: 24, height: 24)
                                                
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .offset(x: 5, y: -5)
                                        }
                                    }

                                    Text(option.name)
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    currentPage = 3
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentColor)
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }
    
    private var gettingStartedView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 30) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(accentColor)
                
                VStack(spacing: 16) {
                    Text("Ready to Start Spotting!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Here's how to get started:")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    OnboardingStepView(
                        icon: "camera.fill",
                        title: "Spot an Aircraft",
                        description: "Take a photo when you see an interesting aircraft",
                        accentColor: accentColor
                    )
                    
                    OnboardingStepView(
                        icon: "plus.circle.fill",
                        title: "Tap the + Button",
                        description: "Add aircraft details like registration and airline",
                        accentColor: accentColor
                    )
                    
                    OnboardingStepView(
                        icon: "book.fill",
                        title: "Build Your Logbook",
                        description: "View your collection in Recent or search for specific aircraft",
                        accentColor: accentColor
                    )
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Button {
                onFinish()
            } label: {
                Text("Start Spotting")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentColor)
                    .cornerRadius(16)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }

    
    private func isColorSelected(_ color: Color) -> Bool {
        color.description == appSettings.accentColor.description
    }
    
    private func iconImage(for filename: String?) -> Image {
        #if canImport(UIKit)
        if let filename = filename, let uiImage = UIImage(named: filename) {
            return Image(uiImage: uiImage)
        } else {
            return Image(uiImage: UIImage(named: "icon-default") ?? UIImage())
        }
        #else
        return Image(systemName: "app.fill")
        #endif
    }
    
    private func changeAppIcon(to iconName: String?) {
        #if canImport(UIKit)
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Failed to change icon: \(error.localizedDescription)")
            } else {
                print("App icon changed to: \(iconName ?? "default")")
            }
        }
        #endif
    }
    
    private func selectIcon(_ iconName: String?) {
        selectedIcon = iconName
        changeAppIcon(to: iconName)
        appSettings.currentAppIcon = iconName
        
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
}

struct OnboardingStepView: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    OnboardingView {
        print("Onboarding finished")
    }
    .environmentObject(AppSettings())
}
