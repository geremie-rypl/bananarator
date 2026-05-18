import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @EnvironmentObject var appState: AppState

    @State private var captureTapped = false

    var body: some View {
        NavigationStack {
            ZStack {
                BananaTheme.partyRadial.ignoresSafeArea()

                if viewModel.isAuthorized {
                    cameraContent
                } else {
                    permissionDeniedView
                }
            }
            .navigationDestination(isPresented: $viewModel.showEditor) {
                if let image = viewModel.capturedImage {
                    EditorView(baseImage: image, onDismiss: {
                        viewModel.resetCapture()
                    })
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var cameraContent: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 4)

            // Camera preview wrapped in a sticker-card
            CameraPreviewView(cameraService: viewModel.cameraService)
                .aspectRatio(3.0/4.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: BananaTheme.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BananaTheme.cardCornerRadius, style: .continuous)
                        .stroke(Color.white, lineWidth: 6)
                )
                .bananaShadow(BananaTheme.cardShadow)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Spacer(minLength: 8)

            controlBar
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }

    private var header: some View {
        BananaBanner("BANANARATOR", subtitle: "Decorate your banana, darling")
            .padding(.bottom, 4)
    }

    private var controlBar: some View {
        HStack(spacing: 32) {
            // Flash toggle
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
            }
            .buttonStyle(BananaCircleButtonStyle(tint: .yellow, size: 56))

            // Capture button (huge, with squeeze animation)
            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) {
                    captureTapped.toggle()
                }
                viewModel.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(BananaTheme.pinkPurple, lineWidth: 8)
                        .frame(width: 108, height: 108)
                        .background(Circle().fill(Color.white))
                        .bananaShadow(BananaTheme.cardShadow)

                    Circle()
                        .fill(BananaTheme.pinkPurple)
                        .frame(width: 76, height: 76)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(Color.white)
                }
                .scaleEffect(captureTapped ? 0.9 : 1.0)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: captureTapped)

            // Camera flip
            Button {
                viewModel.toggleCamera()
            } label: {
                Image(systemName: "camera.rotate.fill")
            }
            .buttonStyle(BananaCircleButtonStyle(tint: .blue, size: 56))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
        )
        .bananaShadow(BananaTheme.cardShadow)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            ConfettiBackground(showsGradient: false)
                .frame(height: 0)
                .opacity(0) // confetti is already in the radial; keep the API consistent

            VStack(spacing: 18) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(BananaTheme.pinkPurple)
                    .padding(20)
                    .background(Circle().fill(Color.white))
                    .bananaShadow(BananaTheme.cardShadow)

                Text("Camera Access Required")
                    .font(BananaTheme.title(24))
                    .foregroundStyle(Color.dapperBrown)

                Text("Bananarator needs camera access to photograph your banana masterpiece.")
                    .font(BananaTheme.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.dapperBrown.opacity(0.75))
                    .padding(.horizontal, 16)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(BananaPillButtonStyle(variant: .primary))
                .padding(.horizontal, 24)
                .padding(.top, 4)
            }
            .padding(28)
            .bananaCard(borderColor: .partyPink, borderWidth: 4, padding: 0)
            .padding(.horizontal, 24)
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let previewLayer = cameraService.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraService.previewLayer {
            previewLayer.frame = uiView.bounds
            if previewLayer.superlayer == nil {
                uiView.layer.addSublayer(previewLayer)
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState())
}
