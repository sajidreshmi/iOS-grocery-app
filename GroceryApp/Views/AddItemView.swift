import SwiftUI
import VisionKit
import Vision
import Combine
import FirebaseStorage // Add this import

// MARK: - ViewModel
class AddItemViewModel: ObservableObject {
    // Published properties to replace @State in the View
    @Published var itemName: String = ""
    @Published var itemQuantityString: String = "1"
    @Published var itemCategory: String = "-- Select Category --"
    @Published var itemDescription: String = ""
    @Published var hasExpiration: Bool = false
    @Published var expirationDate: Date = Date()
    @Published var inputImage: UIImage?
    @Published var recognizedText: String = ""
    @Published var isRecognizing: Bool = false
    @Published var isDescriptionExpanded: Bool = false
    @Published var isLoading: Bool = false // For the loading indicator

    // Popover State
    @Published var showingMessagePopover: Bool = false
    @Published var popoverMessage: String = ""
    @Published var isErrorPopover: Bool = false

    // Image Picker related state
    @Published var showingImagePicker = false
    @Published var showingSourcePicker = false
    @Published var sourceType: UIImagePickerController.SourceType = .camera

    // Constants
    let categories = ["-- Select Category --", "Dairy", "Bakery", "Meat & Seafood", "Breakfast", "Frozen Foods", "Snacks", "Beverages","Spices & Cereals","Other"]
    let collapsedHeight: CGFloat = 50
    let expandedHeight: CGFloat = 200

    // Computed property for validation
    var isAddItemDisabled: Bool {
        itemName.isEmpty || Int(itemQuantityString) == nil || Int(itemQuantityString) ?? 0 <= 0 || itemCategory == categories[0] || isLoading
    }

    // Dependencies
    private var inventoryManager: InventoryManager
    private var dismissAction: () -> Void = {}

    init(inventoryManager: InventoryManager) {
        self.inventoryManager = inventoryManager
    }

    func setDismissAction(_ action: @escaping () -> Void) {
        self.dismissAction = action
    }

    // MARK: - Image Handling & Text Recognition
    func handleImageChange(newImage: UIImage?) {
         if let image = newImage {
             recognizeText(from: image)
         } else {
             // Clear recognized text only if the image is explicitly removed
             // If a new image is picked, recognizeText will clear it anyway
             if newImage == nil {
                 recognizedText = ""
             }
         }
     }

    func recognizeText(from uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else {
            print("Failed to get CGImage.")
            // Optionally set an error state here
            return
        }

        isRecognizing = true
        recognizedText = "" // Clear previous results before starting new recognition

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest { [weak self] (request, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRecognizing = false
                if let error = error {
                    print("Text recognition error: \(error.localizedDescription)")
                    // Optionally set an error state to show the user
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("Text recognition failed: Could not cast results.")
                    return
                }

                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                // Sort observations by their position instead of strings
                let sortedObservations = observations.sorted {
                    let box1 = $0.boundingBox
                    let box2 = $1.boundingBox
                    return box1.minY > box2.minY // Sort from top to bottom
                }
                let sortedStrings = sortedObservations.compactMap { $0.topCandidates(1).first?.string }
                self.recognizedText = sortedStrings.joined(separator: "\n")
            }
        }
        request.recognitionLevel = .accurate // Or .fast

        // Perform the request asynchronously to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isRecognizing = false
                    print("Failed to perform text recognition request: \(error)")
                    // Optionally set an error state
                }
            }
        }
    }

    // MARK: - Text Recognition Usage
    func useRecognizedText() {
        guard !recognizedText.isEmpty else { return }
        // Prioritize filling item name if empty
        if itemName.isEmpty {
            itemName = recognizedText.lines.first ?? ""
        } else {
            // Append to description if not empty
            itemDescription += (itemDescription.isEmpty ? "" : "\n") + recognizedText
        }
        // Clear recognized text after using it
        recognizedText = ""
    }

    // Inside class AddItemViewModel
    // MARK: - Add Item Logic
    func uploadImageAndAddItem(image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        return imageData.base64EncodedString()
    }

    func addItem() {
        guard let quantity = Int(itemQuantityString), quantity > 0 else {
            showPopover(message: "Invalid quantity entered.", isError: true)
            return
        }

        isLoading = true

        Task {
            var imageURL: String? = nil
            var thumbnailData: String? = nil
            
            if let image = inputImage {
                imageURL = await uploadImageToStorage(image: image)
                thumbnailData = createThumbnailData(image: image)
            }
            
            let newItem = GroceryItem(
                name: itemName,
                quantity: quantity,
                expirationDate: hasExpiration ? expirationDate : nil,
                category: itemCategory,
                imageURL: imageURL,
                thumbnailData: thumbnailData,
                description: itemDescription.isEmpty ? nil : itemDescription
            )

            let successResult = await inventoryManager.addItem(
                name: newItem.name,
                quantity: newItem.quantity,
                expirationDate: newItem.expirationDate,
                category: newItem.category,
                imageURL: newItem.imageURL,
                thumbnailData: newItem.thumbnailData,
                description: newItem.description
            )

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                
                if successResult {
                    self.showPopover(message: "Item added successfully!", isError: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismissAction()
                    }
                } else {
                    self.showPopover(message: "Failed to add item. Please try again.", isError: true)
                }
            }
        }
    }

    // MARK: - Popover Helper
    private func showPopover(message: String, isError: Bool) {
        self.popoverMessage = message
        self.isErrorPopover = isError
        self.showingMessagePopover = true

        // Automatically hide the popover after a delay (e.g., 3 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            // Check if the message is still the same one we showed,
            // avoids dismissing a newer message prematurely
            if self?.popoverMessage == message {
                self?.showingMessagePopover = false
            }
        }
    }

    // MARK: - Image Source Selection
     func selectSource(_ source: UIImagePickerController.SourceType) {
         self.sourceType = source
         self.showingImagePicker = true
     }

     // MARK: - Image Removal
     func removeImage() {
         inputImage = nil
         // recognizedText = "" // handleImageChange will clear this
     }
}

// MARK: - Form Content View (Uses ViewModel)
struct AddItemFormContentView: View {
    @ObservedObject var viewModel: AddItemViewModel

    var body: some View {
        Form {
            nameSection
            descriptionSection
            imageSection
            textRecognitionSection
            detailsSection
        }
    }

    // MARK: Form Sections (Bound to ViewModel)

    private var nameSection: some View {
        HStack {
            TextField("Item Name", text: $viewModel.itemName)
            Button {
                viewModel.showingSourcePicker = true
            } label: {
                Image(systemName: "camera.fill")
            }
        }
    }

    private var descriptionSection: some View {
        Section(header: Text("Description")) {
            // Use a ZStack to overlay the placeholder if needed, or simplify
            TextEditor(text: $viewModel.itemDescription)
                .frame(height: viewModel.isDescriptionExpanded ? viewModel.expandedHeight : viewModel.collapsedHeight)
                .border(Color(UIColor.systemGray5), width: 1) // Consider using RoundedRectangle overlay for better corner radius handling
                .cornerRadius(5) // Apply cornerRadius after border if using .border

            // Show More/Less button only if content exceeds collapsed height potentially
            // Or simply if description is not empty
            if !viewModel.itemDescription.isEmpty {
                Button(viewModel.isDescriptionExpanded ? "Show Less" : "Show More") {
                    withAnimation(.easeInOut) { viewModel.isDescriptionExpanded.toggle() }
                }
                .font(.caption)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 2) // Add a little space
            }
        }
    }

    private var imageSection: some View {
        Section(header: Text("Image")) {
            VStack { // Use VStack for layout
                if let currentImage = viewModel.inputImage {
                    Image(uiImage: currentImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 150) // Limit height
                        .cornerRadius(8) // Add some rounding
                        .padding(.vertical)
                        .onTapGesture { viewModel.showingSourcePicker = true }
                } else {
                    Button("Add Image") { viewModel.showingSourcePicker = true }
                        .frame(maxWidth: .infinity, minHeight: 50) // Ensure button has some size
                        .buttonStyle(.bordered) // Give it some style
                }

                if viewModel.inputImage != nil {
                    Button("Remove Image", role: .destructive) {
                        viewModel.removeImage()
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var textRecognitionSection: some View {
        if viewModel.isRecognizing {
            Section(header: Text("Recognizing Text...")) {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        } else if !viewModel.recognizedText.isEmpty {
            Section(header: Text("Recognized Text (Tap to Use)")) {
                Text(viewModel.recognizedText)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading) // Ensure text aligns left
                    .onTapGesture {
                        viewModel.useRecognizedText()
                    }
            }
        }
        // No view is added if neither condition is met
    }

    private var detailsSection: some View {
        Section(header: Text("Details")) { // Add Section header for clarity
            HStack { // Keep label and field together
                Text("Quantity:")
                TextField("Quantity", text: $viewModel.itemQuantityString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing) // Align number to the right
            }

            Picker("Category", selection: $viewModel.itemCategory) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            // .pickerStyle(.menu) // Default style in Form is often good

            Toggle("Has Expiration Date?", isOn: $viewModel.hasExpiration.animation())

            if viewModel.hasExpiration {
                DatePicker("Expiration Date", selection: $viewModel.expirationDate, displayedComponents: .date)
                    // Ensure DatePicker doesn't get pushed off screen on smaller devices if needed
            }
        }
    }
}


// MARK: - Main AddItemView (Uses ViewModel)
struct AddItemView: View { // Assuming this is your main view struct
    @StateObject var viewModel: AddItemViewModel
    @Environment(\.dismiss) var dismiss

    init(inventoryManager: InventoryManager) {
        _viewModel = StateObject(wrappedValue: AddItemViewModel(inventoryManager: inventoryManager))
    }

    var body: some View {
        ZStack(alignment: .bottom) { // Wrap content in ZStack, align popover bottom
            NavigationView {
                AddItemFormContentView(viewModel: viewModel)
                    .navigationTitle("Add New Item")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                viewModel.addItem()
                            }
                            .disabled(viewModel.isAddItemDisabled)
                            .overlay( // Show loading indicator on Add button
                                viewModel.isLoading ? ProgressView().padding(.leading, -20) : nil
                            )
                        }
                    }
                    // Removed sheet modifiers from here if they were inside NavigationView
            }
            // Removed sheet modifiers from here if they were outside NavigationView but inside ZStack

            // --- Popover View ---
            if viewModel.showingMessagePopover {
                Text(viewModel.popoverMessage)
                    .padding()
                    .background(viewModel.isErrorPopover ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal) // Add some horizontal padding
                    .padding(.bottom, 20) // Lift it from the very bottom edge
                    .transition(.move(edge: .bottom).combined(with: .opacity)) // Add animation
                    .zIndex(1) // Ensure it's on top
                    .onTapGesture { // Allow tapping to dismiss
                        viewModel.showingMessagePopover = false
                    }

            }
        }
        // --- Move Sheet Modifiers Here ---
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(selectedImage: $viewModel.inputImage, sourceType: viewModel.sourceType)
                .onDisappear {
                    viewModel.handleImageChange(newImage: viewModel.inputImage)
                }
        }
        .actionSheet(isPresented: $viewModel.showingSourcePicker) {
            ActionSheet(title: Text("Select Image Source"), buttons: [
                .default(Text("Camera")) { viewModel.selectSource(.camera) },
                .default(Text("Photo Library")) { viewModel.selectSource(.photoLibrary) },
                .cancel()
            ])
        }
        .onAppear {
            viewModel.setDismissAction {
                dismiss()
            }
        }
    }
}

// MARK: - Helper Extensions/Structs (Keep if needed)

// ImagePicker struct remains the same (assuming it exists elsewhere or is defined below)
// struct ImagePicker: UIViewControllerRepresentable { ... }

// String extension remains useful
extension String {
    var lines: [String] {
        self.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

// MARK: - Preview Provider
struct AddItemView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy InventoryManager for the preview
        AddItemView(inventoryManager: InventoryManager())
    }
}


extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

func createThumbnailData(image: UIImage) -> String? {
    let thumbnailImage = image.resized(toWidth: 300) // Add resizing extension
    return thumbnailImage?.jpegData(compressionQuality: 0.5)?.base64EncodedString()
}

func uploadImageToStorage(image: UIImage) async -> String? {
    guard let imageData = image.jpegData(compressionQuality: 0.7) else { return nil }
    
    let storageRef = Storage.storage().reference()
    let imageName = UUID().uuidString
    let imageRef = storageRef.child("itemImages/\(imageName).jpg")
    
    do {
        let _ = try await imageRef.putDataAsync(imageData)
        return try await imageRef.downloadURL().absoluteString
    } catch {
        print("Error uploading image: \(error.localizedDescription)")
        return nil
    }
}
