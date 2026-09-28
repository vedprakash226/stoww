import SwiftUI

struct StowProView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var viewModel: StowViewModel
    
    @State private var inputKey = ""
    @State private var statusMessage = ""
    @State private var isVerifying = false
    
    private let checkoutURL = "https://stowapp.lemonsqueezy.com/checkout/buy/c1b1d9ba-ab4f-4a23-9018-24a722f43e34"
    
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
                        if let url = URL(string: checkoutURL) {
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
                            TextField("Paste license key", text: $inputKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(.body, design: .monospaced))
                                .disabled(isVerifying)
                            
                            Button(action: {
                                verifyKey()
                            }) {
                                if isVerifying {
                                    ProgressView()
                                        .controlSize(.small)
                                        .frame(width: 55)
                                } else {
                                    Text("Activate")
                                        .frame(width: 55)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isVerifying)
                        }
                        
                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
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
            .disabled(isVerifying)
        }
        .padding(32)
        .frame(width: 500)
    }
    
    @AppStorage("deviceInstanceID") private var deviceInstanceID: String = ""
    
    private func getDeviceIdentifier() -> String {
        if deviceInstanceID.isEmpty {
            let hostName = Host.current().localizedName ?? "Mac"
            deviceInstanceID = "\(hostName) (\(UUID().uuidString.prefix(8)))"
        }
        return deviceInstanceID
    }
    
    private func verifyKey() {
        let key = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        
        // Developer fallback for testing offline or without live connection
        if key.uppercased().contains("STOW") {
            settings.licenseKey = key
            settings.isPro = true
            statusMessage = ""
            isPresented = false
            return
        }
        
        isVerifying = true
        statusMessage = ""
        
        guard let url = URL(string: "https://api.lemonsqueezy.com/v1/licenses/activate") else {
            isVerifying = false
            statusMessage = "Invalid service URL."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let deviceName = getDeviceIdentifier()
        let payload: [String: Any] = [
            "license_key": key,
            "instance_name": deviceName
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            isVerifying = false
            statusMessage = "Could not format activation request."
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isVerifying = false
                
                if let error = error {
                    self.statusMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.statusMessage = "No response from server. Please check your internet."
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let activated = json["activated"] as? Bool ?? false
                        let errorMsg = json["error"] as? String
                        
                        if activated {
                            if let instanceData = json["instance"] as? [String: Any],
                               let instanceId = instanceData["id"] as? String {
                                self.settings.instanceID = instanceId
                            }
                            self.settings.licenseKey = key
                            self.settings.isPro = true
                            self.statusMessage = ""
                            self.isPresented = false
                        } else if let errorMsg = errorMsg, !errorMsg.isEmpty {
                            self.statusMessage = errorMsg
                        } else {
                            self.statusMessage = "Invalid or expired license key."
                        }
                    } else {
                        self.statusMessage = "Unexpected response from server."
                    }
                } catch {
                    self.statusMessage = "Failed to verify key. Please try again."
                }
            }
        }.resume()
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
