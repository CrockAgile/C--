#include <stdlib.h>
#include <stdio.h>

#include "lib.h"

extern int yylex();
extern int yyparse();
extern token yytoken;
extern YYSTYPE root;
extern FILE* yyin;
extern FILE* yyout;

void call_parsing(int, char**);

int main(int argc, char** argv) {
    if (!init_nametable()){
        fprintf(stderr,"Failed to initialize nametable\n");
        exit(1);
    }
    call_parsing(argc, argv);
    return 0;
}

void call_parsing(int argc, char** argv) {
    int i;
    for (i = 1; i < argc; i++){
        yytoken.filename = argv[i];
        yyin = fopen(argv[i],"r");
        if( !yyparse() ) {
            printf("\n***%s***\n",argv[i]);
            treeprint(root,0);
        }
    }
}
