#include <winsock2.h>
#include <ws2tcpip.h>

#include <chrono>
#include <cstdio>
#include <print>
#include <thread>
#pragma comment(lib, "Ws2_32.lib")

#include "InputParser.h"
#include "sendInput.h"

int main(int argc, const char* argv[]) {
    WSADATA wsaData;
    int     wsaerr;
    WORD    wVersionRequested = MAKEWORD(2, 2);
    wsaerr                    = WSAStartup(wVersionRequested, &wsaData);
    constexpr int receiveSize = 200;
    int           listenPort  = 55555;
    std::string   address     = "192.168.1.175";
    InputParser   parser{receiveSize};
    if (argc == 3) {
        std::println("accepting user set ip and port");
        const char* newAddress = argv[1];
        const char* port       = argv[2];
        address.assign(newAddress);
        listenPort = std::atoi(port);
    }

    if (wsaerr != 0) {
        std::println("The Winsock dll not found!");
        return 0;
    }

    SOCKET serverSocket;
    serverSocket = INVALID_SOCKET;
    serverSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    if (serverSocket == INVALID_SOCKET) {
        std::println("Error at socket(): {}", WSAGetLastError());
        WSACleanup();
        return 0;
    }

    sockaddr_in service;
    service.sin_family = AF_INET;
    if (inet_pton(AF_INET, address.c_str(), &service.sin_addr.s_addr) != 1) {
        std::println("Error at address conversion: {}", WSAGetLastError());
        WSACleanup();
        return 0;
    }

    service.sin_port = htons(listenPort);  // Choose a port number
    if (bind(serverSocket, reinterpret_cast<SOCKADDR*>(&service), sizeof(service)) == SOCKET_ERROR) {
        std::println("bind() failed: {}", WSAGetLastError());
        closesocket(serverSocket);
        WSACleanup();
        return 0;
    }

    if (listen(serverSocket, 1) == SOCKET_ERROR) {
        std::println("listen(): Error listening on socket: {}", WSAGetLastError());
    } else {
        std::println("server created, listening...");
    }

    // Accept incoming connections
    SOCKET      acceptSocket;
    SOCKADDR_IN clientInfo = {0};

    int addressSize = sizeof(clientInfo);
    acceptSocket    = accept(serverSocket, reinterpret_cast<sockaddr*>(&clientInfo), &addressSize);

    // Check for successful connection
    if (acceptSocket == INVALID_SOCKET) {
        std::println("accept failed: {}", WSAGetLastError());
        WSACleanup();
        return -1;
    } else {
        char clientAddress[16] = "";
        inet_ntop(AF_INET, &clientInfo.sin_addr, reinterpret_cast<PSTR>(clientAddress),
                  sizeof(clientAddress));
        std::println("listening from ip {}", clientAddress);
    }

    char receiveBuffer[receiveSize];
    bool is_running = true;
    int  counter    = 0;
    while (is_running) {
        int receivedBytes = recv(acceptSocket, receiveBuffer, receiveSize, 0);
        if (receivedBytes < 0) {
            std::println("Server recv error: ", WSAGetLastError());
            is_running = false;
        } else if (receivedBytes == 0) {
            std::println("server end of transmission");
            is_running = false;
        } else {
            std::string temp;
            temp.assign(receiveBuffer, receivedBytes);
            std::println("received packet {}", temp);
            parser.consumeSymbols(receiveBuffer, receivedBytes);
            std::optional<std::string> symbol;
            std::string                actualSymbol;
            while (symbol = parser.getNextSymbol('{', '}')) {
                actualSymbol = symbol.value();
                sendInput(actualSymbol);
            }
            std::println("");
        }
        counter++;
    }
    return 0;
}

int testParser() {
    std::println("hello world!");

    char testString1[] = "{this}{is}{something}{here}";
    char testString2[] = "{There}{are}{a}{b}";
    char testString3[] = "{andALototherTHings}";

    InputParser parser{5};
    parser.consumeSymbols(testString1, sizeof(testString1));
    parser.debugPrint();
    std::optional<std::string> firstOutput = parser.getNextSymbol('{', '}');
    if (firstOutput) {
        std::println("first output is {}", firstOutput.value());
    }
    std::optional<std::string> secondOutput = parser.getNextSymbol('{', '}');
    if (secondOutput) {
        std::println("second output is {}", secondOutput.value());
    }
    parser.consumeSymbols(testString2, sizeof(testString2));
    parser.debugPrint();
    std::optional<std::string> result;
    while (result = parser.getNextSymbol('{', '}')) {
        std::println("extracted symbol {}", result.value());
        parser.debugPrint();
    }
    parser.consumeSymbols(testString3, sizeof(testString3));
    std::println("outside the loop-------------");
    parser.debugPrint();
    result = parser.getNextSymbol('{', '}');
    std::println("extracted symbol {}", result.value());
    parser.debugPrint();
    std::println("end of buffer");
    return 0;
}

int testSimulateInput() {
    using namespace std::literals::chrono_literals;
    InputParser parser{200};
    std::string input =
        "{Shift}{H}{Shift_up}{E}{L}{L}{O}{ }{Shift}{W}{Shift_up}{O}{R}{L}{D}{Shift}{1}{Shift_up}";
    parser.consumeSymbols(input.c_str(), 88);
    std::optional<std::string> result;
    for (int i = 10; i > 0; i--) {
        std::println("seconds left: {}", i);
        std::this_thread::sleep_for(1s);
    }
    while (result = parser.getNextSymbol('{', '}')) {
        std::string symbol = result.value();
        sendInput(symbol);
    }
    return 0;
}