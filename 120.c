#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "parse.h"

extern token yytoken;
extern YYSTYPE root;
FILE* yyin;

int parsetree_setup(int,char**);
void parsetree_teardown();
void call_parsing(char*);

int main(int argc, char** argv) {
    if( parsetree_setup(argc, argv) ) {
    // have parse trees available to work with
        print_treelist(treelist_head);
    }
    parsetree_teardown();
    return 0;
}

int parsetree_setup(int argc,char **argv) {
    int c, index, verbose_mode = 0;
    opterr = 0;
    while ((c = getopt (argc, argv, "v")) != -1)
        switch(c) {
            case 'v': // verbose mode to print tree
                verbose_mode = 1;
                break;
        } 

    if (!init_nametable()) {
        fprintf(stderr,"Failed to initialize nametable\n");
        exit(1);
    }

    for (index=optind; index < argc; index++)
        call_parsing(argv[index]);

    return verbose_mode;
}

void parsetree_teardown() {
    free_treelist(treelist_head);
    free_nametable();
}

void call_parsing(char* filename) {
    int parse_result;
    yytoken.filename = filename;
    yyin = fopen(filename,"r");
    parse_result = yyparse();
    if ( parse_result == 1 ) {
        exit(2); // exit 2 for a parse error
    }
    treelist_append(filename,root);
    fclose(yyin); // close them file pointers!
}
