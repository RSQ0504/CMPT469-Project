#pragma once
#define NOMINMAX
#include "InputParser.h"

#include <WinSock2.h>

#include <algorithm>
#include <cstddef>
#include <iostream>
#include <print>

InputParser::InputParser(int bufferCapacity) : bufferCapacity(bufferCapacity) {
    parserBuffer = new char[bufferCapacity]();  // the round brackets zero the memory
}

InputParser::~InputParser() {
    delete[] parserBuffer;
    parserBuffer   = nullptr;
    bufferCapacity = 0;
}

void InputParser::consumeSymbols(const char* streamBuffer, const int incomingBufferSize) {
    while (bufferLength + incomingBufferSize > bufferCapacity) {
        if (safeDoubleCapacity() != 0) {
            std::println("cannot double capacity correctly");
            return;
        }
    }
    int bytesBeforeWrap = bufferCapacity - (bufferBeginIndex + lenBeforeWrap());
    int remainingBytes  = incomingBufferSize - bytesBeforeWrap;
    std::copy_n(streamBuffer, bytesBeforeWrap, parserBuffer + bufferEndIndex - 1);
    std::copy_n(streamBuffer + bytesBeforeWrap, remainingBytes, parserBuffer + lenAfterWrap());
    bufferEndIndex = (remainingBytes > 0) ? remainingBytes + 1 : bufferEndIndex + incomingBufferSize;
    bufferLength += incomingBufferSize;
    return;
}

std::optional<std::string> InputParser::getNextSymbol(const char beginSymbol, const char endSymbol) {
    if (bufferLength == 0) {
        return std::nullopt;
    }
    char* endBeforeWrap     = parserBuffer + bufferBeginIndex + lenBeforeWrap();
    char* openingBracketPos = std::find(parserBuffer + bufferBeginIndex, endBeforeWrap, beginSymbol);

    // opening bracket wraparound case
    if (openingBracketPos == endBeforeWrap) {
        openingBracketPos = std::find(parserBuffer, parserBuffer + lenAfterWrap(), beginSymbol);
        char* closingBracketPos = std::find(openingBracketPos, parserBuffer + lenAfterWrap(), endSymbol);
        if (closingBracketPos == parserBuffer + lenAfterWrap()) {
            return std::nullopt;
        }
        std::string symbolString;
        std::size_t symbolLen = closingBracketPos - openingBracketPos + 1;
        symbolString.assign(openingBracketPos, symbolLen);
        bufferBeginIndex += symbolLen;
        bufferBeginIndex %= bufferCapacity;
        bufferLength -= symbolLen;
        resetPosition();
        return std::make_optional(symbolString);
    }

    // opening bracket no wraparound cases

    char* closingBracketPos = std::find(openingBracketPos, endBeforeWrap, endSymbol);
    // closing bracket no wraparound case
    if (closingBracketPos != endBeforeWrap) {
        std::string symbolString;
        std::size_t symbolLen = closingBracketPos - openingBracketPos + 1;
        symbolString.assign(openingBracketPos, symbolLen);
        bufferBeginIndex += symbolLen;
        bufferLength -= symbolLen;
        resetPosition();
        return std::make_optional(symbolString);
    }
    if (bufferBeginIndex + bufferLength <= bufferCapacity) {
        return std::nullopt;
    }

    // closing bracket wraparound case
    char* endAfterWrap = parserBuffer + lenAfterWrap();
    closingBracketPos  = std::find(parserBuffer, endAfterWrap, endSymbol);
    if (closingBracketPos == endAfterWrap) {
        return std::nullopt;
    }
    std::string symbolBeforeWrap, symbolAfterWrap;
    std::size_t symbolLen = lenBeforeWrap() + (closingBracketPos - parserBuffer) + 1;
    symbolBeforeWrap.assign(openingBracketPos, lenBeforeWrap());
    symbolAfterWrap.assign(parserBuffer, symbolLen - lenBeforeWrap());
    bufferBeginIndex += symbolLen;
    bufferBeginIndex %= bufferCapacity;
    bufferLength -= symbolLen;
    resetPosition();
    return std::make_optional(symbolBeforeWrap + symbolAfterWrap);
}

void InputParser::debugPrint() {
    std::println("------------------------------debug------------------------------");
    std::println("the current start position is {}", bufferBeginIndex);
    std::println("the current end position is {}", bufferEndIndex);
    std::println("the current buffer length is {}", bufferLength);
    std::println("the current capacity is {}", bufferCapacity);
    std::println("lenBeforeWrap Evaluates to", lenBeforeWrap());
    std::println("lenAftrerWrap evaluates to", lenAfterWrap());
    std::string bufferCopy{}, wrapAround{};

    bufferCopy.assign(parserBuffer, bufferCapacity);

    std::println("the current memory in buffer looks like:");
    std::println("------------------------------");
    std::println("{}", bufferCopy);
    std::println("------------------------------");
    bufferCopy.clear();
    bufferCopy.assign(parserBuffer + bufferBeginIndex, lenBeforeWrap());
    wrapAround.assign(parserBuffer, lenAfterWrap());
    std::println("the reordered layout looks like");
    std::println("------------------------------");
    std::println("{}", bufferCopy + wrapAround);
    std::println("------------------------------");
    std::println("----------------------------debug end----------------------------");
    return;
}

constexpr int InputParser::lenBeforeWrap() {
    return std::min(bufferBeginIndex + bufferLength, bufferCapacity) - bufferBeginIndex;
}

constexpr int InputParser::lenAfterWrap() { return bufferLength - lenBeforeWrap(); }

void InputParser::resetPosition() {
    if (bufferLength == 0) {
        bufferBeginIndex = 0;
        bufferEndIndex   = 1;
    }
}

int InputParser::safeDoubleCapacity() {
    if (bufferCapacity == 0) return -1;
    char* newBuffer = new char[bufferCapacity * 2]();
    // if no wraparound, the second copy_n won't do anything
    std::copy_n(parserBuffer + bufferBeginIndex, lenBeforeWrap(), newBuffer);
    std::copy_n(parserBuffer, lenAfterWrap(), newBuffer + lenBeforeWrap());
    delete[] parserBuffer;
    parserBuffer     = newBuffer;
    bufferBeginIndex = 0;
    bufferEndIndex   = bufferLength + 1;
    bufferCapacity *= 2;
    std::println("capacity increase to {}", bufferCapacity);
    return 0;
}