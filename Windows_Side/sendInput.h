#pragma once
#include <windows.h>

#include <string>

void sendInput(const std::string& symbol);

void sendSpecial(WORD key, bool isRelease);

void sendSingleChar(const char input, bool isRelease);

void testStringInput(const std::string& input);