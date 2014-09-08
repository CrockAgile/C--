#include <stdlib.h>
#include <stdio.h>

extern int yylex();
extern FILE* yyin;
extern FILE* yyout;

int main(int argc, char** argv) {
    int _ = 10;
    return _;
}
