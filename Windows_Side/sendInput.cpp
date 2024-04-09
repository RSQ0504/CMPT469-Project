#pragma once

#include "sendInput.h"

#include <cctype>
#include <chrono>
#include <map>
#include <print>
#include <thread>

// defined especially for US Layout with MacOS/iPadOS names
std::map<std::string, WORD> SpecialKeys = {
    {"Shift", VK_SHIFT},      {"Control", VK_CONTROL}, {"Command", VK_LWIN},   {"Option", VK_MENU},
    {"Capslock", VK_CAPITAL}, {"Enter", VK_RETURN},    {"Backspace", VK_BACK}, {"Tab", VK_TAB},
    {"[", VK_OEM_4},          {"]", VK_OEM_6},         {":", VK_OEM_1},        {"'", VK_OEM_7},
    {",", VK_OEM_COMMA},      {".", VK_OEM_PERIOD},    {"?", VK_OEM_2},        {"|", VK_OEM_5},
    {" ", VK_SPACE}};

void sendInput(const std::string& symbol) {
    bool isRelease       = false;
    int  baseSymbolEnd   = symbol.size() - 1;
    int  baseSymbolStart = 1;
    if (baseSymbolEnd > 3 && symbol.substr(baseSymbolEnd - 3, 3) == "_up") {
        isRelease = true;
        baseSymbolEnd -= 3;
    }
    std::string peeledSymbol = symbol.substr(baseSymbolStart, baseSymbolEnd - baseSymbolStart);
    if (SpecialKeys.contains(peeledSymbol)) {
        WORD symbolKey = SpecialKeys.find(peeledSymbol)->second;
        sendSpecial(symbolKey, isRelease);
        return;
    }
    sendSingleChar(peeledSymbol.at(0), isRelease);
    return;
}

void sendSpecial(WORD key, bool isRelease) {
    INPUT inputCache[1];
    memset(inputCache, 0, sizeof(inputCache));
    inputCache[0].type   = INPUT_KEYBOARD;
    inputCache[0].ki.wVk = key;
    if (isRelease) inputCache[0].ki.dwFlags = KEYEVENTF_KEYUP;
    UINT uSent = SendInput(1, inputCache, sizeof(INPUT));
    return;
}

// single alphabet or number only
void sendSingleChar(const char input, bool isRelease) {
    INPUT inputCache[1];
    memset(inputCache, 0, sizeof(inputCache));
    if (isupper(input) || isdigit(input)) {
        inputCache[0].type   = INPUT_KEYBOARD;
        inputCache[0].ki.wVk = input;

        if (isRelease) inputCache[0].ki.dwFlags = KEYEVENTF_KEYUP;

        UINT uSent = SendInput(1, inputCache, sizeof(INPUT));
        if (uSent != 1) {
            std::println("sendInput {} failed", input);
        } else {
            std::println("successfully sent upper character {}", input);
        }
    } else {
        std::println("uncaught input!!!__________");
    }
    return;
}

void testStringInput(const std::string& input) {
    using namespace std::literals::chrono_literals;
    for (int i = 10; i > 0; i--) {
        std::println("remaining seconds {}", i);
        std::this_thread::sleep_for(1s);
    }

    for (const auto i : input) {
        sendSingleChar(i, true);
        sendSingleChar(i, false);
        std::this_thread::sleep_for(1ms);
    }
    return;
}
