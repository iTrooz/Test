#include "stdio.h"
#include "lib.h"
#include <stdexcept>

int main(){
   try {
      printf("%i\n", addition(3, 4));
   } catch(const std::exception &e) {
      printf("Caught error\n");
   }
}
