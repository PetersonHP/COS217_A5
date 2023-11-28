#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

void genWhitespace(int length) {
   return;
}

void genRandom(int length) {
   int i = 0;
   char c;
   
   for (; i < length; i++) {
      c = (char) rand() % 127;
      putchar(c);
   }
}

int main(int argc, char *argv[]) {
   int length;
   char mode;
   
   assert(argc == 3);

   mode = **(argv + 1);
   length = atoi(*(argv + 2));

   switch(mode) {
      case 'w':
         genWhitespace(length);
         break;
      case 'r':
         genRandom(length);
         break;
   }

   return 0;
}
