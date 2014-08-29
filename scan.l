%{
#include <stdlib.h>
#include "y.tab.h"

void yyerror(char *);
%}

%%
[0-9]+  {
          yylval = atoi(yytext);
          return INTEGER;
        }

[-+\n]  return *yytext;

[ \t]   ;

.       yyerror("invalid character\n");
%%
int yywrap(void) {
  return 1;
}
