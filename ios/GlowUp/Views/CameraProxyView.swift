import SwiftUI
import UIKit
import AVFoundation

struct CameraProxyView: View {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        if hasCamera {
            ActualCameraView { image in
                onCapture(image)
                dismiss()
            }
            .ignoresSafeArea()
        } else {
            VStack(spacing: 20) {
                Image(systemName: "camera.metering.unknown")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.pink)
                Text("Camera Unavailable")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Install this app on your device via the Rork App to use the camera.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Close") { dismiss() }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Theme.pink, in: .capsule)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.screenGradient.ignoresSafeArea())
        }
    }
}

struct ActualCameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        nonisolated func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            Task { @MainActor in
                if let image { self.onCapture(image) }
            }
        }

        nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in
                picker.dismiss(animated: true)
            }
        }
    }
}
