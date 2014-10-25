#include <stdlib.h>
#include <stdio.h>

#include "parse.h"

extern int yylex();
extern int yyparse();
extern int errors;
extern token yytoken;
extern YYSTYPE root;
extern FILE* yyin;
extern FILE* yyout;

void call_parsing(char*,int);

int main(int argc, char** argv) {
    int i,print_mode = 0;
    if (!init_nametable()){
        fprintf(stderr,"Failed to initialize nametable\n");
        exit(1);
    }
    
    for (i=1; i<argc; i++) {
        if (strcmp(argv[i], "-v")) {
            call_parsing(argv[i],print_mode);
        }
        else {
            print_mode = 1;
        }
    }
    return 0;
}

void call_parsing(char* filename,int print_mode) {
    int i, parse_result;
    yytoken.filename = filename;
    yyin = fopen(filename,"r");
    parse_result = yyparse();
    if( (parse_result == 0 ) && print_mode) {
        printf("\n***%s***\n",filename);
        treeprint(root,0);
        freetree(root);
        free_nametable();
    } else if ( parse_result == 1 ) {
        exit(2);
    }
}
