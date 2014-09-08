#include <stdlib.h>
#include <stdio.h>

extern int yylex();
extern int yylineno;
extern int yyleng;
extern char* yytext;
extern FILE* yyin;
extern FILE* yyout;

int main(int argc, char** argv) {
    yyin = fopen(argv[1],"r");
    int x;
    do {
        x = yylex();
        printf("%s:%d:%d\n",yytext,x,yylineno);
    } while(x);
}
