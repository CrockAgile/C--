#include <stdlib.h>
#include <stdio.h>

#include "lexlib.h"

extern int yylex();
extern token yytoken;
extern FILE* yyin;
extern FILE* yyout;

void call_lexing(int, char**);

int main(int argc, char** argv) {
    call_lexing(argc, argv);
    // syntactics
    // semantics
    // intermediate code
    // optimize
    // final code

    // should clean up linked list when done with it but
    // since this stage ends now is faster to simply exit
}

void call_lexing(int argc, char** argv) {
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
