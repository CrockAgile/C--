O	[0-7]
D	[0-9]
L	[_a-zA-Z]
H	[a-fA-F0-9]
E	[Ee][+-]?{D}+
FS	[fFlL]
IS	[uUlL]

%{
#define MAX_STR_CONST 10000 // what practical limits to set?
#define MAX_INCLUDE_DEPTH 100
#define MAX_FNAME_LENGTH 300

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "lexlib.h"

token yytoken = {0,NULL,0,NULL,NULL};

void lexerr(char* s);

int errors;

char string_buf[MAX_STR_CONST];
char origin_buf[MAX_STR_CONST];
char* str_buf_ptr;
char* origin_ptr;
float* float_ptr;
int* int_ptr;

YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_stack_ctr = 0;

// system includes
int iostream_included = 0;
int cstdlib_included = 0;
int ctime_included = 0;
int string_included = 0;
int fstream_included = 0;
int cstring_included = 0;
int iomanip_included = 0;
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

break			return update_yytoken(BREAK,NULL);
bool			return update_yytoken(BOOLEAN,NULL);
case			return update_yytoken(CASE,NULL);
char			return update_yytoken(CHAR,NULL);
class			return update_yytoken(CLASS,NULL);
const			return update_yytoken(CONST,NULL);
continue		return update_yytoken(CONTINUE,NULL);
default			return update_yytoken(DEFAULT,NULL);
delete			return update_yytoken(DELETE,NULL);
do				return update_yytoken(DO,NULL);
double			return update_yytoken(DOUBLE,NULL);
else			return update_yytoken(ELSE,NULL);
extern			return update_yytoken(EXTERN,NULL);
float			return update_yytoken(FLOAT,NULL);
for				return update_yytoken(FOR,NULL);
if				return update_yytoken(IF,NULL);
int				return update_yytoken(INT,NULL);
long			return update_yytoken(LONG,NULL);
namespace		return update_yytoken(NAMESP,NULL);
new				return update_yytoken(NEW,NULL);
private			return update_yytoken(PRIVATE,NULL);
public			return update_yytoken(PUBLIC,NULL);
return			return update_yytoken(RETURN,NULL);
short			return update_yytoken(SHORT,NULL);
signed			return update_yytoken(SIGNED,NULL);
sizeof			return update_yytoken(SIZEOF,NULL);
static			return update_yytoken(STATIC,NULL);
struct			return update_yytoken(STRUCT,NULL);
switch			return update_yytoken(SWITCH,NULL);
typedef			return update_yytoken(TYPEDEF,NULL);
unsigned		return update_yytoken(UNSIGNED,NULL);
using			return update_yytoken(USING,NULL);
void			return update_yytoken(VOID,NULL);
while			return update_yytoken(WHILE,NULL);

{L}({L}|{D})*	return update_yytoken(IDENTIFIER,NULL);

0[xX]{H}+{IS}?	lexerr("Hex not supported");
0{O}+{IS}?		lexerr("Octal not supported");

{D}+{IS}?	{
				int_ptr = (int*)malloc(sizeof(int));
				*int_ptr = atoi(yytext);
				return update_yytoken(ICON,int_ptr);
			}

{D}*"."{D}+({E})?{FS}?	|
{D}+"."{D}*({E})?{FS}?	|
{D}+{E}{FS}?	{
				float_ptr = (float*)malloc(sizeof(float));
				*float_ptr = atof(yytext);
				return update_yytoken(FCON,float_ptr);
				}


'([^\\'])+'	{
				str_buf_ptr = (char*)malloc(strlen(yytext)+1);
				strcpy(str_buf_ptr,yytext+1);
				str_buf_ptr[yyleng-2] = '\0';
				return update_yytoken(CCON,str_buf_ptr);
			}

'\\.'		{
				str_buf_ptr = (char*)malloc(4);
				strcpy(str_buf_ptr,yytext+1);
				str_buf_ptr[2] = '\0';
				escape_char(str_buf_ptr,str_buf_ptr);
				str_buf_ptr[1] = '\0';
				return update_yytoken(CCON,str_buf_ptr);
			}

		/* shamelessly taken from flex man page and tweaked	*/

"#"[ \t\f]*"include"[ \t\f]*	yy_push_state(include);
<include>\"[^ \t\n\f]+\"	{	// user include as in "foo.h"
		if( include_stack_ctr >= MAX_INCLUDE_DEPTH) {
			lexerr("Includes nested too deeply");
			exit(1);
		}
		include_stack[include_stack_ctr++] = YY_CURRENT_BUFFER;
		yytext++[yyleng-1] = '\0';	// strip quotes
		yyin = fopen(yytext, "r");

		if (!yyin)
			lexerr("Include file could not be found");

		push_file(yylineno);
		yytoken.filename = strdup(yytext);
		yylineno = 1;
		yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));

		yy_pop_state();
}

<include>"<iostream>"	iostream_included = 1; yy_pop_state();
<include>"<cstdlib>"	cstdlib_included = 1; yy_pop_state();
<include>"<ctime>"		ctime_included = 1; yy_pop_state();
<include>"<string>"		string_included = 1; yy_pop_state();
<include>"<fstream>"	fstream_included = 1; yy_pop_state();
<include>"<cstring>"	cstring_included = 1; yy_pop_state();
<include>"<iomanip>"	iomanip_included = 1; yy_pop_state();

<INITIAL><<EOF>> {
		if( --include_stack_ctr < 0) {
			yylineno = 1;
			yyterminate();
		}
		else {
			yy_delete_buffer( YY_CURRENT_BUFFER);
			yylineno = pop_file();
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

\"	{
		str_buf_ptr = string_buf;
		origin_ptr = origin_buf;
		*origin_ptr++ = '\"';
		yy_push_state(string);
	}

<string>{
	\"		{
				yy_pop_state();
				*str_buf_ptr = '\0';
				*origin_ptr++ = '\"';
				*origin_ptr = '\0';
				return lval_update_yytoken(STRING,strdup(string_buf),origin_buf);
			}
	\n		lexerr("unterminated string constant");
	<<EOF>>	lexerr("reached EOF while in string");
	\\		|
	\\0		|
	\\a		|
	\\b		|
	\\n		|
	\\t		|
	\\r		|
	\\f		|
	\\\'	|
	\\v		|
	\\\"	{
				strcpy(origin_ptr,yytext);
				origin_ptr += 2;
				escape_char(yytext,str_buf_ptr++);
			}

	[^\\\n\"]+	{ 	char* yptr = yytext;
					while ( *yptr ) {
						*origin_ptr++ = *yptr;
						*str_buf_ptr++ = *yptr++;
					}
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
"?"			return update_yytoken(OPERATOR,NULL);


;			return update_yytoken(SM,NULL);
,			return update_yytoken(CM,NULL);
:			return update_yytoken(COLON,NULL);
"{"			return update_yytoken(LC,NULL);
"}"			return update_yytoken(RC,NULL);
"("			return update_yytoken(LP,NULL);
")"			return update_yytoken(RP,NULL);
"["			return update_yytoken(LB,NULL);
"]"			return update_yytoken(RB,NULL);

<*>.|\n     lexerr("Unrecognized lexeme"); return 0;

%%

void lexerr(char* s)
{
	errors++;

	fprintf(stderr, "lexical error: %s\n", s);

	fprintf(stderr, "(%s:%d)\ttoken = \"%s\"\n",
		yytoken.filename,
		yylineno,
		yytext);
}

int yywrap()
{
	return 1;
}
