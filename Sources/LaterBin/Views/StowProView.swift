import SwiftUI

struct StowProView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var viewModel: LaterBinViewModel
    
    @State private var inputKey = ""
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Text("Get Stow Pro")
                    .font(.system(size: 32, weight: .bold))
                
                Text("One-time payment. Yours forever.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Feature List
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "infinity", title: "Unlimited Stows", description: "Bypass the 3-file free limit and stow as many files, folders, and links as you need simultaneously.")
                
                FeatureRow(icon: "clock.badge.exclamationmark", title: "Advanced Retention", description: "Keep your files on the shelf indefinitely, or set exact custom expiration dates so they auto-clean themselves.")
                
                FeatureRow(icon: "sparkles", title: "Free Lifetime Updates", description: "Pay once and get all future macOS compatibility updates, bug fixes, and new features for free.")
                
                FeatureRow(icon: "heart.fill", title: "Support Indie Mac Dev", description: "Directly support the solo developer building native, lightweight utilities for your Mac.")
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Checkout / License Section
            VStack(spacing: 16) {
                if settings.isPro {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Stow Pro is Unlocked")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Button(action: {
                        // Opens your Lemon Squeezy link
                        if let url = URL(string: "https://yourwebsite.com/buy") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("Buy Lifetime License — $19.99")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    
                    VStack(spacing: 8) {
                        Text("Already have a license key?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("STOW-XXXX-YYYY", text: $inputKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(.body, design: .monospaced))
                            
                            Button("Activate") {
                                verifyKey()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(inputKey.isEmpty)
                        }
                        
                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.top, 8)
            
            Button("Maybe Later") {
                isPresented = false
            }
            .buttonStyle(.link)
            .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(width: 500)
    }
    
    private func verifyKey() {
        if inputKey.uppercased().contains("STOW") {
            settings.licenseKey = inputKey
            settings.isPro = true
            statusMessage = ""
            
            // Close the modal
            isPresented = false
            
            // Trigger notch window visibility after sheet animation finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("ShowProSuccess"), object: nil)
            }
        } else {
            statusMessage = "Invalid License Key."
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
