#pragma once
#include <optional>
#include <string>
#include <vector>

class InputParser {
   public:
    InputParser(int bufferCapacity);

    ~InputParser();

    std::optional<std::string> getNextSymbol(const char beginSymbol, const char endSymbol);

    void consumeSymbols(const char* streamBuffer, const int bufferSize);

    void debugPrint();

   private:
    constexpr int lenBeforeWrap();
    constexpr int lenAfterWrap();
    
    void resetPosition();
    int safeDoubleCapacity();

    int   bufferBeginIndex = 0;
    int   bufferEndIndex   = 1;  // exclusive, 1 + (the position to insert next)
    int   bufferLength     = 0;
    int   bufferCapacity   = 0;
    char* parserBuffer     = nullptr;
};