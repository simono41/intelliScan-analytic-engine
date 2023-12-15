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
    @State private var isShowingPopup = false
    @State private var matchedLines: [String] = []
    @State private var textRectangles: [RectangleData] = []

    var body: some View {
        ZStack {
            CameraView(recognizedText: $recognizedText, isShowingPopup: $isShowingPopup, matchedLines: $matchedLines, textRectangles: $textRectangles)
                .edgesIgnoringSafeArea(.all)

            // Overlay für die Rechtecke
            ForEach(textRectangles) { rectangleData in
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: rectangleData.rect.width, height: rectangleData.rect.height)
                    .position(x: rectangleData.rect.midX, y: rectangleData.rect.midY)
                    .rotationEffect(Angle(degrees: 270))
            }
            //Text("Recognized Text: \(recognizedText)")
            //                .padding()
        }
        .alert(isPresented: $isShowingPopup) {
            Alert(
                title: Text("Text Match Found"),
                message: Text("Found matching text: \(matchedLines.joined(separator: "\n"))"),
                dismissButton: .default(Text("OK")) {
                    // Hier kannst du zusätzlichen Code für das Schließen des Popups hinzufügen
                }
            )
        }
    }
}

struct RectangleData: Identifiable {
    var id: UUID
    var rect: CGRect
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var isShowingPopup: Bool
    @Binding var matchedLines: [String]
    @Binding var textRectangles: [RectangleData]

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

                    let rectangles = results.map { observation in
                        let boundingBox = observation.boundingBox
                        let transformedRect = self.parent.transformRect(boundingBox)
                        return RectangleData(id: UUID(), rect: transformedRect)
                    }

                    DispatchQueue.main.async {
                        self.parent.recognizedText = text
                        self.parent.textRectangles = rectangles
                        print(text)
                        self.parent.checkForRegexMatch(text)
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

    func checkForRegexMatch(_ text: String) {
        // Hier kannst du dein eigenes Regex-Muster einfügen
        let regexPattern = "[\\-öÖäÄüÜß.a-zA-Z\\s]{8,50}[\\d]{1,3}"

        let lines = text.components(separatedBy: .newlines)

        matchedLines = lines.filter { line in
            if let matchPercentage = percentageMatch(text: line, pattern: regexPattern), matchPercentage >= 60.0 {
                print("Found matching text: \(line) with \(matchPercentage)% confidence")
                return true
            }
            return false
        }

        isShowingPopup = !matchedLines.isEmpty
    }

    func percentageMatch(text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            let matchLength = match.range.length
            let textLength = text.utf16.count
            let matchPercentage = Double(matchLength) / Double(textLength) * 100.0
            print("\(text) Match Percentage: \(matchPercentage)%")
            return matchPercentage
        }

        return 0.0
    }

    func transformRect(_ rect: CGRect) -> CGRect {
        let previewSize = UIScreen.main.bounds.size
        var transformedRect = VNImageRectForNormalizedRect(rect, Int(previewSize.width), Int(previewSize.height))
        transformedRect.origin.x = previewSize.width - transformedRect.origin.x - transformedRect.size.width
        
        return transformedRect
    }
}
