import Foundation

// Define the host and port of the server
let host = "localhost"
let port = 8080

// Create a TCP client class
class TCPClient {
    let host: String
    let port: Int
    var inputStream: InputStream?
    var outputStream: OutputStream?
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
        self.connect()
    }
    
    func connect() {
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        inputStream?.open()
        outputStream?.open()
    }
    
    func send(message: String) {
        let data = message.data(using: .utf8)!
        _ = data.withUnsafeBytes { outputStream?.write($0, maxLength: data.count) }
    }
    
    func disconnect() {
        inputStream?.close()
        outputStream?.close()
    }
}
