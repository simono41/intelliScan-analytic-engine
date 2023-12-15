//
//  ContentView.swift
//  intelliScan-analytic-engine
//
//  Created by Simon Rieger on 15.12.23.
//

import SwiftUI
import AVFoundation
import Vision

struct LiveTextRecognitionView: View {
    @State private var recognizedText = ""

    var body: some View {
        VStack {
            CameraView(recognizedText: $recognizedText)
                .edgesIgnoringSafeArea(.all)
                .onDisappear {
                    CameraView.stopSession()
                }

            Text("Live erkannter Text:")
                .padding()
            Text(recognizedText)
                .padding()
                .background(Color.white.opacity(0.7))
        }
    }
}

struct LiveTextRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        LiveTextRecognitionView()
    }
}

struct CameraView: UIViewRepresentable {
    @Binding var recognizedText: String

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var recognizedText: Binding<String>
        var request: VNRecognizeTextRequest?

        init(recognizedText: Binding<String>) {
            self.recognizedText = recognizedText
            super.init()

            setupVision()
        }

        func setupVision() {
            request = VNRecognizeTextRequest(completionHandler: { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

                var recognizedText = ""
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    recognizedText += topCandidate.string + "\n"
                }

                self.recognizedText.wrappedValue = recognizedText
            })

            request?.recognitionLevel = .accurate
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])

            do {
                try handler.perform([request!])
            } catch {
                print("Error performing OCR: \(error)")
            }
        }
    }

    static var session: AVCaptureSession?

    static func startSession() {
        session?.startRunning()
    }

    static func stopSession() {
        session?.stopRunning()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(recognizedText: $recognizedText)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else { return view }
        let input = try? AVCaptureDeviceInput(device: device)

        if session.canAddInput(input!) {
            session.addInput(input!)
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "cameraQueue"))

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        // Todo: get PreviewLayer working
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        CameraView.session = session

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        if context.coordinator.request == nil {
            context.coordinator.setupVision()
        }

        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            CameraView.startSession()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    CameraView.startSession()
                }
            }
        }
    }
}
