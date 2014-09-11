O	[0-7]
D	[0-9]
L	[_a-zA-Z]
H	[a-fA-F0-9]
E	[Ee][+-]?{D}+
FS	[fFlL]
IS	[uUlL]

		// TODO use ytab.h instead ?

%{
#define MAX_STR_CONST 10000 // what practical limits to set?
#define MAX_INCLUDE_DEPTH 100
#define MAX_FNAME_LENGTH 300

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "cgram.tab.h"
#include "lexlib.h"

extern YYSTYPE yylval;
extern int yychar;
token yytoken = {0,NULL,0,NULL,NULL};

void lexerr(char* s);

int prev_state;
int errors;
FILE* saved_yyin;

char lexeme_buf[MAX_STR_CONST];
char string_buf[MAX_STR_CONST];
char filename_buff[MAX_FNAME_LENGTH] = {0};
char* string_buf_ptr;
char* lexeme_buf_ptr;

YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_stack_ctr = 0;
%}

%x star_comment
%x line_comment
%x include
%x string
%x chara

%option yylineno
%option stack

%%

\n
[ \t\f]+

break			return BREAK;
case			return CASE;
char			return CHAR;
class			return CLASS;
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
private			return PRIVATE;
public			return PUBLIC;
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

0[xX]{H}+{IS}?	lexerr("Hex not supported\n");
0{O}+{IS}?		lexerr("Octal not supported\n");

{D}+{IS}?					return ICON;
{D}+{E}{FS}?				return FCON;
{D}*"."{D}+({E})?{FS}?		return FCON;
{D}+"."{D}*({E})?{FS}?		return FCON;
'([^\\'])+'					yytext++[yyleng-1] = '\0'; return CCON;
'\\.'		{
				yytext++[yyleng-1] = '\0'; // strip quotes
				escape_char(yytext++,yytext+1);
				return CCON;
			}

		/* shamelessly taken from flex man page and tweaked	*/

"#"[ \t\f]*"include"[ \t\f]*	yy_push_state(include);
<include>\"[^ \t\n\f]+\"	{	// user include as in "foo.h"
		if( include_stack_ctr >= MAX_INCLUDE_DEPTH) {
			lexerr("Includes nested too deeply\n");
			exit(1);
		}
		include_stack[include_stack_ctr++] = YY_CURRENT_BUFFER;
		yytext++[yyleng-1] = '\0';	// strip quotes
		yyin = fopen(yytext, "r");

		if (!yyin)
			lexerr("Include file could not be found\n");

		push_file(yytoken.filename,yylineno);
		free(yytoken.filename);
		yytoken.filename = strdup(yytext);
		print_filestack();
		yylineno = 1;
		yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));

		yy_pop_state();
}
<include>\<[^ \t\n\f]+\>	// library include

<INITIAL><<EOF>> {
		if( --include_stack_ctr < 0) {
			yyterminate();
		}
		else {
			yy_delete_buffer( YY_CURRENT_BUFFER);
			memset(&filename_buff[0],0,sizeof(filename_buff));
			yylineno = pop_file(filename_buff);
			free(yytoken.filename);
			yytoken.filename = strdup(filename_buff);
			print_filestack();
			yy_switch_to_buffer(include_stack[include_stack_ctr]);
		}
}

"/*"			yy_push_state(star_comment);
<star_comment>{
	[^*\n]*
	"*"+[^*/\n]*
	\n
	"*"+"/"		yy_pop_state();
}

"//"			yy_push_state(line_comment);
<line_comment>{
	[^\n]*
	\n			yy_pop_state();
}

			/* TODO decide how to limit string length */

\"	string_buf_ptr = string_buf; yy_push_state(string);

<string>{
	\"		yy_pop_state(); *string_buf_ptr = '\0'; printf("%s",string_buf); return STRING; // TODO return string
	\n		lexerr("unterminated string constant\n");
	<<EOF>>	lexerr("reached EOF while in string\n");
	\\		|
	\\a		|
	\\b		|
	\\n		|
	\\t		|
	\\r		|
	\\f		|
	\\\'	|
	\\v		|
	\\\"	escape_char(yytext,string_buf_ptr++);

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
"="				|
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
::			|
"?"			return OPERATOR;


;			return SM;
,			return CM;
:			return COLON;
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
