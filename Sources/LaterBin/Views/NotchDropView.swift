import SwiftUI
import UniformTypeIdentifiers

struct NotchDropView: View {
    @EnvironmentObject var viewModel: LaterBinViewModel
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isEdgeTargeted {
                VStack(spacing: 12) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color.accentColor)
                    
                    Text("Drop to save in LaterBin")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 240, height: 180)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 15)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .scale(scale: 0.8)).combined(with: .opacity)
                ))
                .padding(.top, 15)
            } else {
                // Invisible target zone hugging the top edge (notch area)
                Rectangle()
                    .fill(Color.black.opacity(0.01))
                    .frame(width: 200, height: 50)
            }
            
            Spacer(minLength: 0)
        }
        .frame(width: 260, height: 240, alignment: .top)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isEdgeTargeted)
        .onDrop(of: [.fileURL, .item], isTargeted: $viewModel.isEdgeTargeted) { providers in
            let handled = viewModel.handleDrop(providers: providers, retention: settings.defaultRetention)
            if handled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(name: NSNotification.Name("HideNotchWindow"), object: nil)
                }
            }
            return handled
        }
    }
}
