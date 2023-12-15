//
//  ContentView.swift
//  intelliScan-analytic-engine
//
//  Created by Simon Rieger on 15.12.23.
//
import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @State private var recognizedText: String = ""
    
    var body: some View {
        VStack {
            CameraView(recognizedText: $recognizedText)
                .edgesIgnoringSafeArea(.all)
            
            Text("Recognized Text: \(recognizedText)")
                .padding()
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    print("Error recognizing text: \(error)")
                    return
                }
                
                if let results = request.results as? [VNRecognizedTextObservation] {
                    let text = results.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }.joined(separator: "\n")
                    
                    DispatchQueue.main.async {
                        self.parent.recognizedText = text
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Error performing OCR: \(error)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
        
        guard let camera = AVCaptureDevice.default(for: .video) else { return viewController }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Error setting up camera input: \(error)")
            return viewController
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "cameraQueue"))
        captureSession.addOutput(output)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
