import SwiftUI
import UIKit

struct RectangleButton: View {
    var size: CGSize
    var name: String
    @State private var dragAmount: CGPoint?
    @State private var rotationAngle: Angle = .zero
    @Binding var isLocked: Bool
    @Binding var selectedButtonNames: [String]

    var body: some View {
        GeometryReader { gp in
            ZStack {
                Button(action: {
                    self.selectedButtonNames.append(self.name)
                    // Trigger haptic feedback
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
                .animation(.default, value: dragAmount)
                .position(self.dragAmount ?? CGPoint(x: gp.size.width / 2, y: gp.size.height / 2))
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { self.dragAmount = isLocked ? self.dragAmount : $0.location }
                )
                .rotationEffect(rotationAngle)

                .gesture(
                    RotationGesture()
                        .onChanged { angle in
                            self.rotationAngle = isLocked ? self.rotationAngle : angle
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    struct RectangleButtonProperties: Identifiable {
        var id = UUID() // Generate unique identifier
        var size: CGSize
        var name: String
        var position: CGPoint // Position of the button
    }

    var body: some View {
        VStack {
            HStack{
                Button(action: { isPopoverPresented.toggle() }) { // Show popover when clicked
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
                    isLocked.toggle()
                }) {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open")
                }
                .padding()

                Button(action: {
                    recallLatestButton()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .padding(.trailing)

                Button(action: {
                    clearTextBoard()
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding()
            }
            Text("\(selectedButtonNames.joined(separator: ""))") // Text box below the lock button
            Divider()
            ZStack {
                ForEach(rectangleButtons) { button in
                    RectangleButton(size: button.size, name: button.name, isLocked: $isLocked, selectedButtonNames: $selectedButtonNames)
                        .position(button.position)
                }
            }
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
        rectangleButtons.append(RectangleButtonProperties(size: size, name: name, position: position))
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
