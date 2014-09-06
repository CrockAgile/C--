O	[0-7]
D	[0-9]
L	[_a-zA-Z]
H	[a-fA-F0-9]
W	[ \t\f]
LIT	\"(\\.|[^\\"])*\"

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "cgram.tab.h"

extern YYSTYPE yylval;
extern int yychar;

void lexerr(char* s);
int user_include();

int line_num = 1;
int errors;
FILE* saved_yyin;
%}

%%

\n		line_num++;
[W]+

break		return BREAK;
case		return CASE;
char		return CHAR;
const		return CONST;
continue	return CONTINUE;
default		return DEFAULT;
do		return DO;
double		return DOUBLE;
else		return ELSE;
extern		return EXTERN;
float		return FLOAT;
for		return FOR;
if		return IF;
int		return INT;
long		return LONG;
return		return RETURN;
short		return SHORT;
signed		return SIGNED;
sizeof		return SIZEOF;
static		return STATIC;
struct		return STRUCT;
switch		return SWITCH;
typedef		return TYPEDEF;
unsigned	return UNSIGNED;
void		return VOID;
while		return WHILE;

{L}({L}{D})*	return IDENTIFIER; // TODO add character constants
{LIT}		return STRING;
"#include"{W}*\"[^\\"]+\"	return user_include();
"#include"{W}*			return 1; // IMPLEMENT STATES

">>="		|
"<<="		|
"+="		|
"-="		|
"*="		|
"/="		|
"%="		|
"&="		|
"^="		|
"|="		|
">>"		|
"<<"		|
"++"		|
"--"		|
"->"		|
"."		|
"&&"		|
"||"		|
"<="		|
">="		|
"=="		|
!=		|
&		|
!		|
~		|
-		|
"+"		|
"*"		|
"/"		|
%		|
"<"		|
">"		|
"^"		|
"|"		|
"?"		return OPERATOR;

;		return SM;
{		return LC;
}		return RC;
,		return CM;
:		return COLON;
=		return ASN;
"("		return LP;
")"		return RP;
"["		return LB;
"]"		return RB;

%%

void lexerr(char* s)
{
	errors++;

	fprintf(stderr, "%s: lexical error", s);

	// TODO add filename and line report

	fprintf(stderr, ", token = \"%s\"\n", yytext);
}

int yywrap()
{
	return 1;
}

int user_include()
{
	return 303;
}
