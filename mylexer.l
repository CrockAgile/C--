D	[0-9]
L	[_a-zA-Z]
H	[a-fA-F0-9]

%{
#define MAX_STR_CONST 10000 // what practical limits to set?
#define MAX_INCLUDE_DEPTH 10

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
int prev_state;
int errors;
FILE* saved_yyin;

char string_buf[MAX_STR_CONST];
char *string_buf_ptr;

YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_stack_ctr = 0;
%}

%x comment
%x include
%x string

%option yylineno

%%

\n			line_num++;
[ \t\f]+

break			return BREAK;
case			return CASE;
char			return CHAR;
const			return CONST;
continue		return CONTINUE;
default			return DEFAULT;
do				return DO;
double			return DOUBLE;
else			return ELSE;
extern			return EXTERN;
float			return FLOAT;
for				return FOR;
if				return IF;
int				return INT;
long			return LONG;
namespace		return NAMESP;
return			return RETURN;
short			return SHORT;
signed			return SIGNED;
sizeof			return SIZEOF;
static			return STATIC;
struct			return STRUCT;
switch			return SWITCH;
typedef			return TYPEDEF;
unsigned		return UNSIGNED;
using			return USING;
void			return VOID;
while			return WHILE;

{L}({L}|{D})*	return IDENTIFIER;

		/* shamelessly taken from flex man page and tweaked	*/

"#include"[ \t\f]*			BEGIN(include);
<include>\"[^ \t\n\f]+\"	{
		if( include_stack_ctr >= MAX_INCLUDE_DEPTH) {
			lexerr("Includes nested too deeply\n");
			exit(1);
		}
		include_stack[include_stack_ctr++] = YY_CURRENT_BUFFER;
		yyin = fopen(yytext, "r");

		if (!yyin)
			lexerr("Include file could not be found\n");

		yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));

		BEGIN(INITIAL);
}
<include>\<		BEGIN(INITIAL);

<INITIAL><<EOF>> {
		if( --include_stack_ctr < 0) {
			yyterminate();
		}
		else {
			yy_delete_buffer( YY_CURRENT_BUFFER);
			yy_switch_to_buffer(include_stack[include_stack_ctr]);
		}
}

"/*"			{ prev_state = INITIAL; BEGIN(comment);}
<comment>{
	[^*\n]*
	"*"+[^*/\n]*
	\n			line_num++;
	"*"+"/"		BEGIN(prev_state);
}

			/* TODO decide how to limit string length */

\"	string_buf_ptr = string_buf; BEGIN(string);

<string>{
	\"		{ BEGIN(INITIAL); *string_buf_ptr = '\0';} // TODO return string
	\n		lexerr("unterminated string constant\n");
	\\{D}+	lexerr("invalid escape sequence\n");
	<<EOF>>	lexerr("reached EOF while in string\n");
	\\n		*string_buf_ptr++ = '\n';
	\\t		*string_buf_ptr++ = '\t';
	\\r		*string_buf_ptr++ = '\r';
	\\b		*string_buf_ptr++ = '\b';
	\\f		*string_buf_ptr++ = '\f';
	\\(.|\n)	*string_buf_ptr++ = yytext[1];
	[^\\\n\"]+	{ 	char* yptr = yytext;
					while ( *yptr )
						*string_buf_ptr++ = *yptr++;
				}
}



">>="			|
"<<="			|
"+="			|
"-="			|
"*="			|
"/="			|
"%="			|
"&="			|
"^="			|
"|="			|
">>"			|
"<<"			|
"++"			|
"--"			|
"->"			|
"."				|
"&&"			|
"||"			|
"<="			|
">="			|
"=="			|
!=			|
&			|
!			|
~			|
-			|
"+"			|
"*"			|
"/"			|
%			|
"<"			|
">"			|
"^"			|
"|"			|
"?"			return OPERATOR;


;			return SM;
,			return CM;
:			return COLON;
=			return ASN;
"{"			return LC;
"}"			return RC;
"("			return LP;
")"			return RP;
"["			return LB;
"]"			return RB;

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
