import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct RectangleButton: View {
    @Binding var size: CGSize
    @Binding var name: String
    @Binding var position: CGPoint // Binding for dragAmount
    @Binding var rotationAngle: Angle // Binding for rotationAngle
    @Binding var isLocked: Bool
    @Binding var selectedButtonNames: [String]

    var body: some View {
        GeometryReader { gp in
            ZStack {
                Button(action: {
                    self.selectedButtonNames.append(self.name)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.blue)
                            .frame(width: size.width, height: size.height)
                        Text(name)
                            .foregroundColor(.white)
                            .font(.system(.caption, design: .serif))
                    }
                }
                .animation(.default, value: position)
                .position(self.position)
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            self.position = isLocked ? self.position : value.location // Update dragAmount
                        }
                )
                .rotationEffect(rotationAngle)

                .gesture(
                    RotationGesture()
                        .onChanged { angle in
                            self.rotationAngle = isLocked ? self.rotationAngle : angle // Update rotationAngle
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    var parent: ContentView?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            let data = try Data(contentsOf: url)
            parent?.handleImportedJSON(data: data)
        } catch {
            print("Error reading file:", error)
        }
    }
}

class SaveDocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    var jsonData: Data?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            if let data = jsonData {
                try data.write(to: url)
                print("JSON data saved to: \(url)")
            }
        } catch {
            print("Error saving JSON data:", error)
        }
    }
}

struct ContentView: View {
    @State private var rectangleButtons: [RectangleButtonProperties] = []
    @State private var widthText: String = "100"
    @State private var heightText: String = "50"
    @State private var newName: String = ""
    @State private var isPopoverPresented = false
    @State private var isLocked = false
    @State private var selectedButtonNames: [String] = []
    @State private var singleLineText: String = ""
    private let documentPickerDelegate = DocumentPickerDelegate()
    private let saveDocumentPickerDelegate = SaveDocumentPickerDelegate()


    struct RectangleButtonProperties: Identifiable, Encodable, Decodable {
        var id = UUID()
        var size: CGSize
        var name: String
        var position: CGPoint
        var rotationAngle: Angle // Include rotation angle
        
        private enum CodingKeys: String, CodingKey {
            case id, size, name, position, rotationAngle
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(size, forKey: .size)
            try container.encode(name, forKey: .name)
            try container.encode(position, forKey: .position)
            try container.encode(rotationAngle.degrees, forKey: .rotationAngle)
        }
        
        init(id: UUID = UUID(), size: CGSize, name: String, position: CGPoint, rotationAngle: Angle) {
            self.id = id
            self.size = size
            self.name = name
            self.position = position
            self.rotationAngle = rotationAngle
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(UUID.self, forKey: .id)
            self.size = try container.decode(CGSize.self, forKey: .size)
            self.name = try container.decode(String.self, forKey: .name)
            self.position = try container.decode(CGPoint.self, forKey: .position)
            let rotationAngleInDegrees = try container.decode(Double.self, forKey: .rotationAngle)
            self.rotationAngle = Angle(degrees: rotationAngleInDegrees)
        }
    }

    var body: some View {
        VStack {
            HStack{
                Button(action: {
                    isLocked.toggle()
                }) {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open")
                }
                .padding()

                if !isLocked {
                    Button(action: { isPopoverPresented.toggle() }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .popover(isPresented: $isPopoverPresented, content: {
                        VStack {
                            HStack {
                                TextField("Width", text: $widthText, onCommit: {})
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                
                                TextField("Height", text: $heightText, onCommit: {})
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            }
                            
                            TextField("Name", text: $newName, onCommit: {})
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            
                            Button("Add", action: {
                                if let width = Double(widthText), let height = Double(heightText) {
                                    addRectangleButton(size: CGSize(width: width, height: height), name: newName)
                                    isPopoverPresented = false // Dismiss popover after adding button
                                }
                            })
                            .padding()
                        }
                        .padding()
                    })
                    
                    Button(action: {
                        removeAllButtons()
                    }) {
                        Image(systemName: "trash")
                    }
                    .padding()
                    Button(action: {
                        recallLatestButton()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .padding(.trailing)
                }
                
                Button(action: {
                    saveRectButtonsToJson()
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title)
                }
                .padding()
                
                Button(action: {
                    importRectButtonsFromJSON()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title)
                }
                .padding()
            }
            HStack{
                Text("\(selectedButtonNames.joined(separator: ""))") // Text box below the lock button
                Button(action: {
                    clearTextBoard()
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding()
            }
            Divider()
            ZStack {
                ForEach(rectangleButtons.indices, id: \.self) { index in
                    RectangleButton(size: self.$rectangleButtons[index].size, // Pass binding
                                    name: self.$rectangleButtons[index].name,
                                    position: self.$rectangleButtons[index].position, // Pass binding
                                    rotationAngle: self.$rectangleButtons[index].rotationAngle, // Pass binding
                                    isLocked: self.$isLocked,
                                    selectedButtonNames: self.$selectedButtonNames)
                    .position(rectangleButtons[index].position)
                        .rotationEffect(rectangleButtons[index].rotationAngle)
                }
            }
        }
        .onAppear {
                documentPickerDelegate.parent = self
            }
    }
    func saveRectButtonsToJson() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(rectangleButtons)
            saveDocumentPickerDelegate.jsonData = jsonData
            let fileManager = FileManager.default
            let fileURL = fileManager.temporaryDirectory.appendingPathComponent("temp.json")
            try jsonData.write(to: fileURL)
            let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
            documentPicker.delegate = saveDocumentPickerDelegate
            UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true, completion: nil)
        } catch {
            print("Error saving rectangle buttons:", error)
        }
    }
    
    func importRectButtonsFromJSON() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = documentPickerDelegate
        UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true, completion: nil)
    }
    
    func handleImportedJSON(data: Data) {
        do {
            let decoder = JSONDecoder()
            let decodedButtons = try decoder.decode([RectangleButtonProperties].self, from: data)
            rectangleButtons.append(contentsOf: decodedButtons)
        } catch {
            print("Error decoding JSON:", error)
        }
    }
    
    func addRectangleButton(size: CGSize, name: String) {
        let centerAreaWidth = UIScreen.main.bounds.width / 2
        let centerAreaHeight = UIScreen.main.bounds.height / 2

        let minX = (UIScreen.main.bounds.width - centerAreaWidth) / 2
        let minY = (UIScreen.main.bounds.height - centerAreaHeight) / 2
        let maxX = minX + centerAreaWidth - size.width
        let maxY = minY + centerAreaHeight - size.height

        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)

        let position = CGPoint(x: randomX, y: randomY)
        let rotationAngle = Angle(degrees: 0.0) // Initial rotation angle
        rectangleButtons.append(RectangleButtonProperties(size: size, name: name, position: position, rotationAngle: rotationAngle))
        widthText = "100"
        heightText = "50"
        newName = ""
    }

    func removeAllButtons() {
        rectangleButtons.removeAll()
        selectedButtonNames.removeAll()
    }

    func recallLatestButton() {
        if !rectangleButtons.isEmpty {
            rectangleButtons.removeLast()
        }
    }

    func clearTextBoard() {
        selectedButtonNames.removeAll()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
