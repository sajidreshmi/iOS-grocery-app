import XCTest

class GroceryAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app = XCUIApplication()
        // We send launch arguments to the app to tell it we are in UI Testing mode.
        // This allows the app to potentially reset state or use mock data.
        app.launchArguments = ["enable-testing"]
        app.launch() // Launch the app
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }

    func testAddItemFlow() throws {
        // Navigate to Add Item screen
        app.navigationBars["Grocery Inventory"].buttons["Add"].tap() // Use the actual title if different

        // Wait for the Add Item sheet to appear
        let addItemNavBar = app.navigationBars["Add New Item"] // Use the actual title
        XCTAssertTrue(addItemNavBar.waitForExistence(timeout: 2), "Add Item sheet did not appear")

        // Fill in the form
        let nameTextField = addItemNavBar.otherElements.containing(.staticText, identifier:"Add New Item").children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .textField).element // Adjust based on actual hierarchy if needed
        let quantityTextField = addItemNavBar.otherElements.containing(.staticText, identifier:"Add New Item").children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .textField).element // Adjust based on actual hierarchy
        let categoryTextField = addItemNavBar.otherElements.containing(.staticText, identifier:"Add New Item").children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .textField).element // Adjust

        let testItemName = "Oranges"
        let testQuantity = "5"
        let testCategory = "Produce"

        nameTextField.tap()
        nameTextField.typeText(testItemName)

        quantityTextField.tap()
        quantityTextField.typeText(testQuantity)

        categoryTextField.tap()
        categoryTextField.typeText(testCategory)

        // Save the item
        addItemNavBar.buttons["Save"].tap()

        // Verify the item appears in the list
        XCTAssertTrue(app.staticTexts[testItemName].waitForExistence(timeout: 2), "Added item name not found in list")
        XCTAssertTrue(app.staticTexts["Quantity: \(testQuantity)"].exists, "Added item quantity not found in list")
        XCTAssertTrue(app.staticTexts["Category: \(testCategory)"].exists, "Added item category not found in list")
    }

    func testEditItemFlow() throws {
        // Pre-condition: Add an item to edit first (or ensure one exists)
        // This might reuse parts of testAddItemFlow or assume initial state
        let initialName = "Butter"
        let initialQuantity = "1"
        app.navigationBars["Grocery Inventory"].buttons["Add"].tap()
        let addItemNavBar = app.navigationBars["Add New Item"]
        XCTAssertTrue(addItemNavBar.waitForExistence(timeout: 2))
        let nameField = addItemNavBar.textFields["Item Name"] // Use accessibility identifiers if possible
        let quantityField = addItemNavBar.textFields["Quantity"]
        nameField.tap()
        nameField.typeText(initialName)
        quantityField.tap()
        quantityField.typeText(initialQuantity)
        addItemNavBar.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts[initialName].waitForExistence(timeout: 2))


        // Tap the item to edit
        app.collectionViews.staticTexts[initialName].tap() // Adjust if using List instead of CollectionView

        // Wait for Edit screen
        let editItemNavBar = app.navigationBars["Edit Item"] // Use the actual title
        XCTAssertTrue(editItemNavBar.waitForExistence(timeout: 2), "Edit Item sheet did not appear")

        // Modify the quantity
        let editQuantityTextField = editItemNavBar.textFields["Quantity"] // Adjust identifier/hierarchy
        let newQuantity = "2"

        editQuantityTextField.tap()
        // Clear existing text (might need multiple deletes depending on cursor position)
        let currentQuantity = editQuantityTextField.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentQuantity.count)
        editQuantityTextField.typeText(deleteString)
        // Type new quantity
        editQuantityTextField.typeText(newQuantity)

        // Save changes
        editItemNavBar.buttons["Save"].tap()

        // Verify changes in the list
        XCTAssertTrue(app.staticTexts[initialName].waitForExistence(timeout: 2), "Item name should still exist")
        XCTAssertTrue(app.staticTexts["Quantity: \(newQuantity)"].exists, "Updated quantity not found in list")
        XCTAssertFalse(app.staticTexts["Quantity: \(initialQuantity)"].exists, "Old quantity should not exist")
    }


    func testDeleteItemFlow() throws {
        // Pre-condition: Add an item to delete
        let itemToDelete = "Yogurt"
        app.navigationBars["Grocery Inventory"].buttons["Add"].tap()
        let addItemNavBar = app.navigationBars["Add New Item"]
        XCTAssertTrue(addItemNavBar.waitForExistence(timeout: 2))
        let nameField = addItemNavBar.textFields["Item Name"]
        let quantityField = addItemNavBar.textFields["Quantity"]
        nameField.tap()
        nameField.typeText(itemToDelete)
        quantityField.tap()
        quantityField.typeText("6") // Add quantity
        addItemNavBar.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts[itemToDelete].waitForExistence(timeout: 2))

        // Find the cell containing the item
        let itemCell = app.collectionViews.cells.containing(.staticText, identifier: itemToDelete).element // Adjust if using List

        // Swipe left to reveal delete button
        itemCell.swipeLeft()

        // Tap the delete button
        // Note: The delete button might be labeled "Delete" or have an icon. Adjust accordingly.
        // If it's a standard swipe-to-delete, the button might be within the cell.
        itemCell.buttons["Delete"].tap() // Common label for standard delete

        // Verify the item is removed
        XCTAssertFalse(app.staticTexts[itemToDelete].exists, "Deleted item should not be present in the list")
    }

    // Example Launch Performance Test (Optional)
    // func testLaunchPerformance() throws {
    //     if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
    //         // Measures how long it takes to launch your application.
    //         measure(metrics: [XCTApplicationLaunchMetric()]) {
    //             XCUIApplication().launch()
    //         }
    //     }
    // }
}

// Helper extension for easier TextField interaction (Optional but recommended)
extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }

        self.tap()

        // Move cursor to the end
        let lowerRightCorner = self.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
        lowerRightCorner.tap()

        // Delete existing text
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)

        // Type new text
        self.typeText(text)
    }
}
