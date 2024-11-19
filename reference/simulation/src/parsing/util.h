#pragma once
#include <string>
#include <exception>

using namespace std;

class ParsingException : public exception {
    private:
        const char* what_val;
    public:
        ParsingException() : what_val("Something went wrong while parsing npy data...") {};
        ParsingException(const char* what): what_val(what) {};
        ParsingException(const string what): what_val(what.c_str()) {};

        virtual const char* what() const noexcept override {
            return what_val;
        }
};