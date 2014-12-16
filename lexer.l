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

#define YYSTYPE struct pnode*

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "parse.h"

void lexerr(char* s);

int lerrors = 0;

YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int include_stack_ctr = 0;

char string_buf[MAX_STR_CONST];
char origin_buf[MAX_STR_CONST];
char* str_buf_ptr;
char* origin_ptr;

float* float_ptr;
int* int_ptr;

token yytoken = {0,NULL,0,NULL,NULL};

// system include flags
int iostream_included = 0;
int cstdlib_included = 0;
int ctime_included = 0;
int string_included = 0;
int fstream_included = 0;
int cstring_included = 0;
int iomanip_included = 0;

int namespace_std = 0;

%}

%x star_comment
%x line_comment
%x include
%x string
%x chara

%option noinput
%option nounput
%option noyy_top_state
%option yylineno
%option stack

%%

\n
[ \r\t\f]+

break			return update_yytoken(BREAK,NULL);
bool			return update_yytoken(BOOL,NULL);
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
extern			lexerr("extern not supported");
false           return update_yytoken(FALSE,NULL);
float			return update_yytoken(FLOAT,NULL);
for				return update_yytoken(FOR,NULL);
if				return update_yytoken(IF,NULL);
int				return update_yytoken(INT,NULL);
long			return update_yytoken(LONG,NULL);
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
true            return update_yytoken(TRUE,NULL);
typedef			return update_yytoken(TYPEDEF,NULL);
unsigned		return update_yytoken(UNSIGNED,NULL);
using			return update_yytoken(USING,NULL);
virtual         lexerr("virtual not supported");
void			return update_yytoken(VOID,NULL);
while			return update_yytoken(WHILE,NULL);

{L}({L}|{D})*	{
                    return update_yytoken(id_check(yytext,IDENTIFIER),NULL);
                }

0[xX]{H}+{IS}?	lexerr("Hex not supported");
0{O}+{IS}?		lexerr("Octal not supported");

{D}+{IS}?	{
				int_ptr = (int*)malloc(sizeof(int));
                if (!int_ptr)
                    exit(1);
				*int_ptr = atoi(yytext);
				return update_yytoken(INTEGER,int_ptr);
			}

{D}*"."{D}+({E})?{FS}?	|
{D}+"."{D}*({E})?{FS}?	|
{D}+{E}{FS}?	{
				float_ptr = (float*)malloc(sizeof(float));
                if (!float_ptr)
                    exit(1);
				*float_ptr = atof(yytext);
				return update_yytoken(FLOATING,float_ptr);
				}


'([^\\'])'	{
				str_buf_ptr = (char*)malloc(strlen(yytext)+1);
                if (!str_buf_ptr)
                    exit(1);
				strcpy(str_buf_ptr,yytext+1);
				str_buf_ptr[yyleng-2] = '\0';
				return update_yytoken(CHARACTER,str_buf_ptr);
			}

'([^\\'])+' {
                lexerr("Character constants cannot contain more than one character");
                str_buf_ptr = malloc(strlen(yytext)+1);
                if (!str_buf_ptr)
                    exit(1);
                strcpy(str_buf_ptr,yytext+1);
                str_buf_ptr[1] = '\0';
                return update_yytoken(CHARACTER,str_buf_ptr);
            }

'\\.'		{
				str_buf_ptr = (char*)malloc(4);
                if (!str_buf_ptr)
                    exit(1);
				strcpy(str_buf_ptr,yytext+1);
				str_buf_ptr[2] = '\0';
				escape_char(str_buf_ptr,str_buf_ptr);
				str_buf_ptr[1] = '\0';
				return update_yytoken(CHARACTER,str_buf_ptr);
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

"using"[\t ]*"namespace"[\t ]*"std"[\t ]*;  {
    if (iostream_included) {
        namespace_std = 1;
        //insert_name($2->t,265);
    }
}


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
	\n		|
	<<EOF>>	{
                lexerr("unterminated string constant");
                yy_pop_state();
                return lval_update_yytoken(STRING,strdup(""),"");
            }
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


">>="		return update_yytoken(SLEQ,NULL);
"<<="		return update_yytoken(SREQ,NULL);
"+="		return update_yytoken(ADDEQ,NULL);
"-="		return update_yytoken(SUBEQ,NULL);
"*="		return update_yytoken(MULEQ,NULL);
"/="		return update_yytoken(DIVEQ,NULL);
"%="		return update_yytoken(MODEQ,NULL);
"&="		return update_yytoken(ANDEQ,NULL);
"^="		return update_yytoken(XOREQ,NULL);
"|="		return update_yytoken(OREQ,NULL);
"="			return update_yytoken('=',NULL);
">>"		return update_yytoken(SR,NULL);
"<<"		return update_yytoken(SL,NULL);
"++"		return update_yytoken(PLUSPLUS,NULL);
"--"		return update_yytoken(MINUSMINUS,NULL);
"->"		return update_yytoken(ARROW,NULL);
"->*"       return update_yytoken(ARROWSTAR,NULL);
"."			return update_yytoken('.',NULL);
"&&"		return update_yytoken(ANDAND,NULL);
"||"		return update_yytoken(OROR,NULL);
"<="		return update_yytoken(LTEQ,NULL);
">="		return update_yytoken(GTEQ,NULL);
"=="		return update_yytoken(EQ,NULL);
!=			return update_yytoken(NOTEQ,NULL);
&			return update_yytoken('&',NULL);
!			return update_yytoken('!',NULL);
~			return update_yytoken('~',NULL);
-			return update_yytoken('-',NULL);
"+"			return update_yytoken('+',NULL);
"*"			return update_yytoken('*',NULL);
"/"			return update_yytoken('/',NULL);
%			return update_yytoken('%',NULL);
"<"			return update_yytoken('<',NULL);
">"			return update_yytoken('>',NULL);
"^"			return update_yytoken('^',NULL);
"|"			return update_yytoken('|',NULL);
::			return update_yytoken(COLONCOLON,NULL);
"?"			return update_yytoken('?',NULL);


;			return update_yytoken(';',NULL);
,			return update_yytoken(',',NULL);
:			return update_yytoken(':',NULL);
"{"			return update_yytoken('{',NULL);
"}"			return update_yytoken('}',NULL);
"("			return update_yytoken('(',NULL);
")"			return update_yytoken(')',NULL);
"["			return update_yytoken('[',NULL);
"]"			return update_yytoken(']',NULL);

<*>.|\n     lexerr("Unrecognized lexeme"); return 0;

%%

void lexerr(char* s)
{
	lerrors++;

	fprintf(stderr, "lexical error: %s\n", s);

    if (yytext[0] == '\n') {
        strcpy(yytext,"\\n\0");
    }

	fprintf(stderr, "(%s:%d)\ttoken = \"%s\"\n",
		yytoken.filename,
		yylineno,
		yytext);

    exit(1);
}

int yywrap()
{
    return 1;
}
