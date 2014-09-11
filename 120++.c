#include <stdlib.h>
#include <stdio.h>
#include "lexlib.h"

extern int yylex();
extern int yylineno;
extern int yyleng;
extern token yytoken;
extern char* yytext;
extern FILE* yyin;
extern FILE* yyout;

int main(int argc, char** argv) {
    int i;
    for (i = 1; i < argc; i++){
        yytoken.filename = argv[i];
        yyin = fopen(argv[i],"r");
        int x;
        do {
            x = yylex();
            printf("%s_%d_%d_%s\n",yytext,x,yylineno,yytoken.filename);
        } while(x);
    }
}
