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
            if( yytoken.code == 264){
                printf("***%s->%s\n",yytoken.text,(char*)yytoken.lval);
            }
            else {
                printf("%d\t%s\t\t%d\t%s\t%p\n",
                    yytoken.code,
                    yytoken.text,
                    yytoken.lineno,
                    yytoken.filename,
                    yytoken.lval
                );
            }
        }
    }
}

void print_yylist(){

}
