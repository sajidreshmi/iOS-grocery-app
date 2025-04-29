import SwiftUI
import Vision

struct AddItemView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss

    @State private var itemName: String = ""
    @State private var itemQuantity: Int? = nil
    @State private var itemCategory: String = ""
    let categories = ["-- Select Category --", "Dairy", "Bakery", "Meat & Seafood", "Breakfast", "Frozen Foods", "Snacks", "Beverages","Spices & Cereals","Other"]
    @State private var expirationDate: Date = Date()
    @State private var hasExpiration: Bool = false

    // State for Image Picker
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    // Add state for choosing the source
    @State private var showingSourcePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera // Default source

    static let quantityFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimum = 1
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                HStack {
                    TextField("Item Name", text: $itemName)
                    Button {
                        // Show the source picker dialog instead of directly showing image picker
                        self.showingSourcePicker = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }

                // Add the image preview section
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .padding(.vertical)
                }

                TextField("Quantity", value: $itemQuantity, formatter: Self.quantityFormatter)
                    .keyboardType(.numberPad)

                Picker("Category", selection: $itemCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
                .onAppear {
                    if itemCategory.isEmpty && !categories.isEmpty {
                        itemCategory = categories[0]
                    }
                }

                Toggle("Has Expiration Date?", isOn: $hasExpiration)
                    .animation(.default, value: hasExpiration)

                if hasExpiration {
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add New Item")
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button("Cancel") {
                         dismiss()
                     }
                 }
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button("Save") {
                         // Convert UIImage to Data before saving
                         let imageData = inputImage?.jpegData(compressionQuality: 0.8) // Adjust compression as needed

                         if let quantity = itemQuantity {
                             inventoryManager.addItem(
                                 name: itemName,
                                 quantity: quantity,
                                 expirationDate: hasExpiration ? expirationDate : nil,
                                 category: itemCategory,
                                 imageData: imageData // Pass the image data
                             )
                             dismiss()
                         } else {
                             print("Invalid quantity (nil)")
                         }
                     }
                     // Update disabled condition for Int? and category placeholder
                     .disabled(itemName.isEmpty || itemQuantity == nil || itemQuantity ?? 0 <= 0 || itemCategory == categories[0])
                 }
            }
            // Add the sheet modifier to present the ImagePicker
            .sheet(isPresented: $showingImagePicker) {
                // Pass the selected sourceType to ImagePicker
                ImagePicker(selectedImage: $inputImage, sourceType: self.sourceType) // Pass sourceType here
            }
            // Add the confirmation dialog
            .confirmationDialog("Choose Image Source", isPresented: $showingSourcePicker, titleVisibility: .visible) {
                Button("Camera") {
                    self.sourceType = .camera
                    self.showingImagePicker = true // Present the sheet
                }
                Button("Photo Library") {
                    self.sourceType = .photoLibrary
                    self.showingImagePicker = true // Present the sheet
                }
                // Cancel button is added automatically
            }
            // Add onChange to process the image when it's selected
            .onChange(of: inputImage) { newImage in
                recognizeText(from: newImage)
            }
        }
    }

    // Function to perform text recognition using Vision
    func recognizeText(from uiImage: UIImage?) {
        guard let uiImage = uiImage, let cgImage = uiImage.cgImage else {
            print("Failed to get CGImage from input image.")
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("Error: Failed to get text recognition results.")
                return
            }

            if let error = error {
                print("Error recognizing text: \(error.localizedDescription)")
                return
            }

            // Process observations
            let recognizedStrings = observations.compactMap { observation in
                // Return the most likely candidate
                observation.topCandidates(1).first?.string
            }

            // Update the item name on the main thread
            DispatchQueue.main.async {
                // You might want more sophisticated logic here,
                // e.g., joining lines, picking the most relevant text, etc.
                self.itemName = recognizedStrings.joined(separator: " ")
                print("Recognized Text: \(self.itemName)")
            }
        }

        // You can adjust recognition level for speed vs. accuracy
        recognizeTextRequest.recognitionLevel = .accurate // or .fast

        do {
            try requestHandler.perform([recognizeTextRequest])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
}

// Placeholder for the ImagePicker struct (See Step 2)
// struct ImagePicker: UIViewControllerRepresentable { ... }

// Remove the duplicate .confirmationDialog modifier from the end of the file if it exists
// It should only be attached to the NavigationView or one of its primary children like Form.
