import SwiftUI

private func singleLineDescription(_ description: String?) -> String? {
    guard let desc = description else { return nil }
    return desc
        .replacingOccurrences(of: "\n", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

struct GroceryItemRow: View {
    let item: GroceryItem
    
    var body: some View {
        HStack {
            if let thumbnailData = item.thumbnailData, 
               let data = Data(base64Encoded: thumbnailData),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.trailing, 5)
            }
            VStack(alignment: .leading) {
                Text(item.name).font(.headline)
                if let description = singleLineDescription(item.description) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Text("Quantity: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if !item.category.isEmpty && item.category != "-- Select Category --" {
                    Text("Category: \(item.category)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                if let expDate = item.expirationDate {
                    Text("Expires: \(expDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            Spacer()
        }
    }
}