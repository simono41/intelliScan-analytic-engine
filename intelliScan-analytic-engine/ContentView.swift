//
//  ContentView.swift
//  intelliScan-analytic-engine
//
//  Created by Simon Rieger on 15.12.23.
//

import SwiftUI
import Vision

struct ContentView: View {
    @State private var recognizedText = ""
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack {
            Button("Bild auswählen") {
                self.showingImagePicker.toggle()
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: recognizeText) {
                ImagePicker(selectedImage: self.$selectedImage, sourceType: .photoLibrary)
            }

            Button("Kamera verwenden") {
                self.showingCamera.toggle()
            }
            .sheet(isPresented: $showingCamera, onDismiss: recognizeText) {
                ImagePicker(selectedImage: self.$selectedImage, sourceType: .camera)
            }

            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()

                Text("Erkannter Text:")
                Text(recognizedText)
                    .padding()
            }
        }
    }

    func recognizeText() {
        guard let selectedImage = selectedImage, let cgImage = selectedImage.cgImage else {
            return
        }

        let request = VNRecognizeTextRequest(completionHandler: { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            var recognizedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                recognizedText += topCandidate.string + "\n"
            }

            self.recognizedText = recognizedText
        })

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing OCR: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    var imagePickerController: UIImagePickerController
    @Environment(\.presentationMode) var presentationMode

    init(selectedImage: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType) {
        _selectedImage = selectedImage
        self.sourceType = sourceType
        imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.allowsEditing = false
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        imagePickerController.delegate = context.coordinator
        return imagePickerController
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}


#Preview {
    ContentView()
}
