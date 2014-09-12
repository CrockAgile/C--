#include <stdlib.h>
#include <stdio.h>

#include "lexlib.h"

extern int yylex();
extern token yytoken;
extern FILE* yyin;
extern FILE* yyout;

void print_yylist();

int main(int argc, char** argv) {
    int i;
    for (i = 1; i < argc; i++){
        yytoken.filename = argv[i];
        yyin = fopen(argv[i],"r");
        while( yylex() ){
            add_to_tail(&yytoken);
        }
        print_tokenlist(tokenlist_head);
    }
}
