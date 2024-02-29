#include "stdio.h"
#include <stdexcept>

int addition(int a, int b){
    throw std::runtime_error("Hey");
    return a+b;
}
