import SwiftUI
import UIKit
import UniformTypeIdentifiers
import AudioToolbox
var client =  TCPClient(host: "127.0.0.1", port: 1000)
struct RectangleButton: View {
    @Binding var size: CGSize
    @Binding var name: String
    @Binding var position: CGPoint // Binding for dragAmount
    @Binding var rotationAngle: Angle // Binding for rotationAngle
    @Binding var isLocked: Bool
    @Binding var selectedButtonNames: [String]
    var client: TCPClient
    @Binding var isSpecial: Bool
    @State private var holdDown = false
    var body: some View {
        GeometryReader { gp in
            ZStack {
                Button(action: {
//                    self.selectedButtonNames.append(self.name)
//                    client.send(message: self.name)
//                    let generator = UIImpactFeedbackGenerator(style: .medium)
//                    generator.impactOccurred()
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
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            self.position = isLocked ? self.position : value.location // Update dragAmount
                            if isLocked && !holdDown{
                                self.selectedButtonNames.append(self.name)
                                client.send(message: "{"+self.name+"}")
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                AudioServicesPlaySystemSound(SystemSoundID(1104))
                                holdDown = true
                            }
                        }
                        .onEnded {value in
                            if isLocked{
                                self.selectedButtonNames.append(self.name)
                                client.send(message: "{"+self.name+"_end}")
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                            holdDown = false
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
    @State private var widthText: String = "75"
    @State private var heightText: String = "75"
    @State private var newName: String = ""
    @State private var isPopoverPresented1 = false
    @State private var isPopoverPresented2 = false
    @State private var isPopoverPresented = false
    @State private var isLocked = false
    @State private var selectedButtonNames: [String] = []
    @State private var singleLineText: String = ""
    @State private var selectedOption = 0 // Default selection
    let names = ["Command", "Shift", "Option", "Control"]
    private let documentPickerDelegate = DocumentPickerDelegate()
    private let saveDocumentPickerDelegate = SaveDocumentPickerDelegate()
    @State private var host = "127.0.0.1"
    @State private var port = 1000
    

    struct RectangleButtonProperties: Identifiable, Encodable, Decodable {
        var id = UUID()
        var size: CGSize
        var name: String
        var position: CGPoint
        var rotationAngle: Angle // Include rotation angle
        var isSpecial: Bool
        
        private enum CodingKeys: String, CodingKey {
            case id, size, name, position, rotationAngle, isSpecial
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(size, forKey: .size)
            try container.encode(name, forKey: .name)
            try container.encode(position, forKey: .position)
            try container.encode(rotationAngle.degrees, forKey: .rotationAngle)
            try container.encode(isSpecial, forKey: .isSpecial)
        }
        
        init(id: UUID = UUID(), size: CGSize, name: String, position: CGPoint, rotationAngle: Angle, isSpecial:Bool) {
            self.id = id
            self.size = size
            self.name = name
            self.position = position
            self.rotationAngle = rotationAngle
            self.isSpecial = isSpecial
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(UUID.self, forKey: .id)
            self.size = try container.decode(CGSize.self, forKey: .size)
            self.name = try container.decode(String.self, forKey: .name)
            self.position = try container.decode(CGPoint.self, forKey: .position)
            let rotationAngleInDegrees = try container.decode(Double.self, forKey: .rotationAngle)
            self.rotationAngle = Angle(degrees: rotationAngleInDegrees)
            self.isSpecial = try container.decode(Bool.self, forKey: .isSpecial)
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
                    Button(action: { isPopoverPresented1.toggle() }) {
                        Image(systemName: "plus")
                    }
                    .padding()
                    .popover(isPresented: $isPopoverPresented1, content: {
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
                                    isPopoverPresented1 = false // Dismiss popover after adding button
                                }
                            })
                            .padding()
                        }
                        .padding()
                    })
                    Button(action: { isPopoverPresented2.toggle() }) {
                        Image(systemName: "plus.circle")
                    }
                    .padding()
                    .popover(isPresented: $isPopoverPresented2, content: {
                        VStack {
                            HStack {
                                TextField("Width", text: $widthText, onCommit: {})
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                
                                TextField("Height", text: $heightText, onCommit: {})
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                            }
                            
                            Picker(selection: $selectedOption, label: Text("Select Name")) {
                                ForEach(0..<names.count) { index in
                                    Text(names[index])
                                }
                            }
                            .pickerStyle(DefaultPickerStyle())
                            .padding()
                            
                            Button("Add", action: {
                                if let width = Double(widthText), let height = Double(heightText) {
                                    addRectangleButtonSpecial(size: CGSize(width: width, height: height), name: names[selectedOption])
                                    isPopoverPresented2 = false // Dismiss popover after adding button
                                }
                            })
                            .padding()
                        }
                        .padding()
                    })
                    
                    Button(action: { isPopoverPresented.toggle() }) {
                        Image(systemName: "link")
                    }
                    .padding()
                    .popover(isPresented: $isPopoverPresented, content: {
                        VStack {
                            HStack {
                                TextField("host", text: $host, onCommit: {})
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                
                                TextField("Port", text: Binding<String>(
                                    get: { String(port) },
                                    set: { newValue in
                                        if let newPort = Int(newValue) {
                                            port = newPort
                                        }
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()

                            }
                        
                            
                            Button("Comfirm", action: {
                                client = TCPClient(host: host, port: port)
                                isPopoverPresented = false // Dismiss popover after adding button
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
            Divider()
            ZStack {
                ForEach(rectangleButtons.indices, id: \.self) { index in
                    RectangleButton(size: self.$rectangleButtons[index].size, // Pass binding
                                    name: self.$rectangleButtons[index].name,
                                    position: self.$rectangleButtons[index].position, // Pass binding
                                    rotationAngle: self.$rectangleButtons[index].rotationAngle, // Pass binding
                                    isLocked: self.$isLocked,
                                    selectedButtonNames: self.$selectedButtonNames,
                                    client:client,
                                    isSpecial: self.$rectangleButtons[index].isSpecial)
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

        let randomX = centerAreaWidth
        let randomY = centerAreaHeight

        let position = CGPoint(x: randomX, y: randomY)
        let rotationAngle = Angle(degrees: 0.0) // Initial rotation angle
        rectangleButtons.append(RectangleButtonProperties(size: size, name: name, position: position, rotationAngle: rotationAngle,isSpecial:false))
        widthText = "75"
        heightText = "75"
        newName = ""
    }
    
    func addRectangleButtonSpecial(size: CGSize, name: String) {
        let centerAreaWidth = UIScreen.main.bounds.width / 2
        let centerAreaHeight = UIScreen.main.bounds.height / 2

        let randomX = centerAreaWidth
        let randomY = centerAreaHeight

        let position = CGPoint(x: randomX, y: randomY)
        let rotationAngle = Angle(degrees: 0.0) // Initial rotation angle
        rectangleButtons.append(RectangleButtonProperties(size: size, name: name, position: position, rotationAngle: rotationAngle,isSpecial:true))
        widthText = "75"
        heightText = "75"
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
