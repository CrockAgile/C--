#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

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
    int c,index,print_mode = 0;
    opterr = 0; // using unistd command line parsing built-ins
    while ((c = getopt (argc, argv, "v")) != -1)
        switch(c) {
            case 'v': // verbose mode to print parse tree
                print_mode = 1;
                break;
        }

    if (!init_nametable()){
        fprintf(stderr,"Failed to initialize nametable\n");
        exit(1);
    }
    // anything not a command flag should be parsed
    for (index=optind; index < argc; index++)
        call_parsing(argv[index],print_mode);
    
    free_nametable();
    return 0;
}

void call_parsing(char* filename,int print_mode) {
    int parse_result;
    yytoken.filename = filename;
    yyin = fopen(filename,"r");
    parse_result = yyparse();
    if( (parse_result == 0 ) && print_mode) {
        printf("\n***%s***\n",filename);
        treeprint(root,0);
    } else if ( parse_result == 1 ) {
        exit(2); // exit 2 for a parse error
    }
    freetree(root); // should each tree be preserved?
    fclose(yyin); // close them file pointers!
}
