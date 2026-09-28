import SwiftUI
import UniformTypeIdentifiers

struct EdgeDropView: View {
    @EnvironmentObject var viewModel: LaterBinViewModel
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        ZStack {
            if viewModel.isEdgeTargeted {
                VStack(spacing: 16) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color.accentColor)
                    
                    Text("Drop to save in LaterBin")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 220, height: 220)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                HStack {
                    Spacer()
                    Image(systemName: "tray.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.accentColor)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .padding(.trailing, 10)
                }
                .frame(width: 220, height: 220, alignment: .trailing)
                .transition(.scale(scale: 0.5).combined(with: .opacity).combined(with: .move(edge: .trailing)))
            }
        }
        .frame(width: 240, height: 240)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isEdgeTargeted)
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isEdgeTargeted) { providers in
            let handled = viewModel.handleDrop(providers: providers, retention: settings.defaultRetention, isPro: settings.isPro)
            if handled {
                NotificationCenter.default.post(name: NSNotification.Name("HideEdgeWindow"), object: nil)
            }
            return handled
        }
    }
}
