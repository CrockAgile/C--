#include <stdlib.h>
#include <stdio.h>

#include "lib.h"

extern int yylex();
extern int yyparse();
extern token yytoken;
extern YYSTYPE yylval;
extern FILE* yyin;
extern FILE* yyout;

void call_lexing(int, char**);

int main(int argc, char** argv) {
    call_lexing(argc, argv);
    printf("%s\n",yylval->t->filename);
    return 0;
}

void call_lexing(int argc, char** argv) {
    int i;
    for (i = 1; i < argc; i++){
        yytoken.filename = argv[i];
        yyin = fopen(argv[i],"r");
        yyparse();
    }
}
