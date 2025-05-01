import SwiftUI
import FirebaseStorage

struct EditItemView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss

    @State private var editableItem: GroceryItem
    @State private var itemQuantityString: String
    @State private var itemDescriptionString: String
    @State private var hasExpiration: Bool
    @State private var expirationDate: Date // Keep track of date separately

    // Image Picker States
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingSourcePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera

    // State for description expansion
    @State private var isDescriptionExpanded: Bool = false

    // Add state for loading indicator
    @State private var isLoading = false

    let categories = ["-- Select Category --", "Dairy", "Bakery", "Meat & Seafood", "Breakfast", "Frozen Foods", "Snacks", "Beverages","Spices & Cereals","Other"]

    // In the init function, replace the inputImage initialization:
    init(inventoryManager: InventoryManager, itemToEdit: GroceryItem) {
        self.inventoryManager = inventoryManager
        _editableItem = State(initialValue: itemToEdit)
        _itemQuantityString = State(initialValue: "\(itemToEdit.quantity)")
        _itemDescriptionString = State(initialValue: itemToEdit.description ?? "")
        _hasExpiration = State(initialValue: itemToEdit.expirationDate != nil)
        _expirationDate = State(initialValue: itemToEdit.expirationDate ?? Date()) // Initialize date

        // Remove this block as imageData no longer exists
        // if let imageData = itemToEdit.imageData {
        //     _inputImage = State(initialValue: UIImage(data: imageData))
        // }

        // TODO: Load image from itemToEdit.imageURL if it exists
        // This will require an asynchronous operation, potentially using .onAppear
        // For now, inputImage will start as nil unless loaded from URL later.
        // Load thumbnail if available
        if let thumbnailData = itemToEdit.thumbnailData,
        let data = Data(base64Encoded: thumbnailData),
        let image = UIImage(data: data) {
        _inputImage = State(initialValue: image)
        } else {
        _inputImage = State(initialValue: nil)
        }
    
        // Ensure category is valid or set default
        if !categories.contains(itemToEdit.category) || itemToEdit.category.isEmpty {
             _editableItem.wrappedValue.category = categories[0] // Use wrappedValue to modify state struct
        }
    }

    static let quantityFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimum = 1
        return formatter
    }()

    // Define estimated heights
    private let collapsedHeight: CGFloat = 50 // Approx height for 2 lines
    private let expandedHeight: CGFloat = 200 // Or adjust as needed

    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    HStack {
                        TextField("Item Name", text: $editableItem.name) // Bind directly
                        Button {
                            self.showingSourcePicker = true
                        } label: {
                            Image(systemName: "camera.fill")
                        }
                    }

                    // Description Section with Expand/Collapse using TextEditor
                    Section(header: Text("Description")) {
                        // Use TextEditor instead of TextField
                        TextEditor(text: $itemDescriptionString)
                            .frame(height: isDescriptionExpanded ? expandedHeight : collapsedHeight)
                            // Add some visual distinction if needed (optional)
                            .border(Color(UIColor.systemGray5), width: 1)
                            .cornerRadius(5)


                        // Only show the button if the text *could* potentially exceed the collapsed height
                        // (This check is imperfect but better than always showing it)
                        if !itemDescriptionString.isEmpty {
                            Button(isDescriptionExpanded ? "Show Less" : "Show More") {
                                withAnimation {
                                    isDescriptionExpanded.toggle()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }


                    // Image Section
                    Section(header: Text("Image")) {
                        if let currentImage = inputImage {
                            Image(uiImage: currentImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 150)
                                .padding(.vertical)
                                .onTapGesture {
                                    self.showingSourcePicker = true
                                }
                            
                            // Button to remove image if it exists
                            Button("Remove Image", role: .destructive) {
                                inputImage = nil
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }


                    TextField("Quantity", text: $itemQuantityString)
                        .keyboardType(.numberPad)

                    Picker("Category", selection: $editableItem.category) { // Bind directly
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Has Expiration Date?", isOn: $hasExpiration.animation())

                    if hasExpiration {
                        DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date) // Use separate date state
                    }
                }
                // Disable the form while loading
                .disabled(isLoading)
                .navigationTitle("Edit Item")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        // Disable Cancel button while loading
                        .disabled(isLoading)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // Make the Button action async
                        Button("Save") {
                            // Use Task for async operation
                            Task {
                                guard let quantity = Int(itemQuantityString), quantity > 0 else {
                                    print("Invalid quantity")
                                    return
                                }

                                isLoading = true
                                
                                // Handle image upload if needed
                                var newImageURL: String? = editableItem.imageURL
                                var newThumbnailData: String? = editableItem.thumbnailData
                                
                                if let image = inputImage {
                                    // Upload new image
                                    do {
                                        let storageRef = Storage.storage().reference()
                                        let imageName = UUID().uuidString
                                        let imageRef = storageRef.child("itemImages/\(imageName).jpg")
                                        let imageData = image.jpegData(compressionQuality: 0.7)!
                                        
                                        // Upload full-size image
                                        _ = try await imageRef.putDataAsync(imageData)
                                        newImageURL = try await imageRef.downloadURL().absoluteString
                                        
                                        // Create thumbnail
                                        if let thumbnail = image.resized(toWidth: 300) {
                                            newThumbnailData = thumbnail.jpegData(compressionQuality: 0.5)?.base64EncodedString()
                                        }
                                    } catch {
                                        print("Image upload failed: \(error.localizedDescription)")
                                    }
                                } else if inputImage == nil { // Explicit image removal
                                    newImageURL = nil
                                    newThumbnailData = nil
                                }

                                // Update the item properties
                                editableItem.quantity = quantity
                                editableItem.description = itemDescriptionString.isEmpty ? nil : itemDescriptionString
                                editableItem.expirationDate = hasExpiration ? expirationDate : nil
                                editableItem.imageURL = newImageURL
                                editableItem.thumbnailData = newThumbnailData
                                
                                await inventoryManager.updateItem(editableItem)
                                
                                isLoading = false
                                dismiss()
                            }
                        }
                        // Update disabled condition to include isLoading
                        .disabled(editableItem.name.isEmpty || Int(itemQuantityString) == nil || Int(itemQuantityString) ?? 0 <= 0 || editableItem.category == categories[0] || isLoading)
                    }
                }
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
                // Optional: Add onChange for inputImage if you want to re-run text recognition during edit
                // .onChange(of: inputImage) { newImage in /* Call recognizeText if needed */ }

                // Conditional ProgressView overlay
                if isLoading {
                    Color.black.opacity(0.4) // Dim background
                        .edgesIgnoringSafeArea(.all)
                    ProgressView("Saving...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } // End ZStack
            .onAppear {
                // Only load from URL if we don't have a local image
                if inputImage == nil, let imageUrlString = editableItem.imageURL, let url = URL(string: imageUrlString) {
                    Task {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                inputImage = image
                            }
                        } catch {
                            print("Error loading image: \(error.localizedDescription)")
                            inputImage = UIImage(systemName: "photo.on.rectangle")
                        }
                    }
                }
            }
        } // End NavigationView
    }
}
