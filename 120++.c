#include <stdlib.h>
#include <stdio.h>

extern int yylex();
extern int yylineno;
extern int yyleng;
extern char* yytext;
extern FILE* yyin;
extern FILE* yyout;

int main(int argc, char** argv) {
    int i;
    for (i = 1; i < argc; i++){
        yyin = fopen(argv[i],"r");
        int x;
        do {
            x = yylex();
            printf("%s_%d_%d\n",yytext,x,yylineno);
        } while(x);
    }
}
