import SwiftUI
import Vision

struct AddItemView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss

    @State private var itemName: String = ""
    @State private var itemDescription: String = ""
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

    // Extracted Form Content
    private var formContent: some View {
        Form {
            HStack {
                TextField("Item Name", text: $itemName)
                Button {
                    self.showingSourcePicker = true
                } label: {
                    Image(systemName: "camera.fill")
                }
            }

            // Display recognized description if available - Changed to TextEditor
            Section(header: Text("Description (Optional)")) {
                 TextEditor(text: $itemDescription)
                     .frame(height: 100) // Adjust height as needed
                     .border(Color(UIColor.systemGray5), width: 1) // Optional border
                     .cornerRadius(5) // Optional corner radius
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
    }

    // Extracted Toolbar Content
    @ToolbarContentBuilder
    private var navigationBarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                let imageData = inputImage?.jpegData(compressionQuality: 0.8)

                if let quantity = itemQuantity {
                    inventoryManager.addItem(
                        name: itemName,
                        quantity: quantity,
                        expirationDate: hasExpiration ? expirationDate : nil,
                        category: itemCategory,
                        imageData: imageData,
                        description: itemDescription.isEmpty ? nil : itemDescription // Argument is present
                    )
                    dismiss()
                } else {
                    print("Invalid quantity (nil)")
                }
            }
            .disabled(itemName.isEmpty || itemQuantity == nil || itemQuantity ?? 0 <= 0 || itemCategory == categories[0])
        }
    }

    var body: some View {
        NavigationView {
            formContent
            .navigationTitle("Add New Item")
            // Use the extracted toolbar content
            .toolbar {
                navigationBarItems
            }
            // Keep other modifiers attached here
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $inputImage, sourceType: self.sourceType)
            }
            .confirmationDialog("Choose Image Source", isPresented: $showingSourcePicker, titleVisibility: .visible) {
                Button("Camera") {
                    self.sourceType = .camera
                    self.showingImagePicker = true
                }
                Button("Photo Library") {
                    self.sourceType = .photoLibrary
                    self.showingImagePicker = true
                }
            }
            .onChange(of: inputImage) { newImage in
                recognizeText(from: newImage)
            }
        }
    }

    // Updated text recognition function
    func recognizeText(from uiImage: UIImage?) {
        guard let uiImage = uiImage, let cgImage = uiImage.cgImage else {
            print("Failed to get CGImage from input image.")
            // Clear previous results if image is removed/fails
            DispatchQueue.main.async {
                self.itemName = ""
                self.itemDescription = ""
            }
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Error: Failed to get text recognition results. \(error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    self.itemName = "" // Clear on error
                    self.itemDescription = ""
                }
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }

            // Simple logic: Use first non-empty string as name, rest as description
            let mainText = recognizedStrings.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? ""
            let descriptionText = recognizedStrings.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async {
                self.itemName = mainText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.itemDescription = descriptionText
                print("Recognized Name: \(self.itemName)")
                print("Recognized Description: \(self.itemDescription)")
            }
        }

        recognizeTextRequest.recognitionLevel = .accurate

        do {
            try requestHandler.perform([recognizeTextRequest])
        } catch {
            print("Unable to perform the text recognition request: \(error).")
            DispatchQueue.main.async {
                self.itemName = "" // Clear on error
                self.itemDescription = ""
            }
        }
    }
}

// Placeholder for the ImagePicker struct (See Step 2)
// struct ImagePicker: UIViewControllerRepresentable { ... }

// Remove the duplicate .confirmationDialog modifier from the end of the file if it exists
// It should only be attached to the NavigationView or one of its primary children like Form.
