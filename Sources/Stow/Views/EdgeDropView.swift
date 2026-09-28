import SwiftUI
import UniformTypeIdentifiers

struct SideDropView: View {
    @EnvironmentObject var viewModel: StowViewModel
    @EnvironmentObject var settings: AppSettings
    
    let isLeft: Bool
    
    private var isTargeted: Binding<Bool> {
        Binding(
            get: { isLeft ? viewModel.isLeftTargeted : viewModel.isRightTargeted },
            set: { newValue in
                if isLeft {
                    viewModel.isLeftTargeted = newValue
                } else {
                    viewModel.isRightTargeted = newValue
                }
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if !isLeft {
                Spacer(minLength: 0)
            }
            
            VStack(spacing: 0) {
                if isTargeted.wrappedValue {
                    VStack(spacing: 12) {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.accentColor)
                        
                        Text("Drop to save in Stow")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 200, height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(isLeft ? .leading : .trailing, 15)
                    .transition(.asymmetric(
                        insertion: .move(edge: isLeft ? .leading : .trailing).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                        removal: .move(edge: isLeft ? .leading : .trailing).combined(with: .scale(scale: 0.8)).combined(with: .opacity)
                    ))
                } else {
                    // Invisible target zone hugging the edge
                    Rectangle()
                        .fill(Color.black.opacity(0.01))
                        .frame(width: 50, height: 200)
                }
            }
            
            if isLeft {
                Spacer(minLength: 0)
            }
        }
        .frame(width: 220, height: 200, alignment: isLeft ? .leading : .trailing)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isTargeted.wrappedValue)
        .onDrop(of: [.fileURL, .item], isTargeted: isTargeted) { providers in
            let handled = viewModel.handleDrop(providers: providers, retention: settings.defaultRetention, isPro: settings.isPro)
            if handled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NotificationCenter.default.post(name: NSNotification.Name("HideEdgeWindows"), object: nil)
                }
            }
            return handled
        }
    }
}
