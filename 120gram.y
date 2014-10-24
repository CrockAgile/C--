/*
 * Grammar for 120++, a subset of C++ used in CS 120 at University of Idaho
 *
 * Adaptation by Clinton Jeffery, with help from Matthew Brown, Ranger
 * Adams, and Shea Newton.
 *
 * Based on Sandro Sigala's transcription of the ISO C++ 1996 draft standard.
 * 
 */

/*	$Id: parser.y,v 1.3 1997/11/19 15:13:16 sandro Exp $	*/

/*
 * Copyright (c) 1997 Sandro Sigala <ssigala@globalnet.it>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * ISO C++ parser.
 *
 * Based on the ISO C++ draft standard of December '96.
 */

%{
#include <stdio.h>
#include "parse.h"

extern token yytoken;
YYSTYPE root = NULL;

static void yyerror(char *s);
%}

%define api.value.type {struct pnode*}

%token IDENTIFIER INTEGER FLOATING CHARACTER STRING
%token TYPEDEF_NAME NAMESPACE_NAME CLASS_NAME ENUM_NAME TEMPLATE_NAME

%token ELLIPSIS COLONCOLON DOTSTAR ADDEQ SUBEQ MULEQ DIVEQ MODEQ
%token XOREQ ANDEQ OREQ SL SR SREQ SLEQ EQ NOTEQ LTEQ GTEQ ANDAND OROR
%token PLUSPLUS MINUSMINUS ARROWSTAR ARROW

%token ASM AUTO BOOL BREAK CASE CATCH CHAR CLASS CONST CONST_CAST CONTINUE
%token DEFAULT DELETE DO DOUBLE DYNAMIC_CAST ELSE ENUM EXPLICIT EXPORT EXTERN
%token FALSE FLOAT FOR FRIEND GOTO IF INLINE INT LONG MUTABLE NAMESPACE NEW
%token OPERATOR PRIVATE PROTECTED PUBLIC REGISTER REINTERPRET_CAST RETURN
%token SHORT SIGNED SIZEOF STATIC STATIC_CAST STRUCT SWITCH TEMPLATE THIS
%token THROW TRUE TRY TYPEDEF TYPEID TYPENAME UNION UNSIGNED USING VIRTUAL
%token VOID VOLATILE WCHAR_T WHILE

%start translation_unit

%%

/*----------------------------------------------------------------------
 * Context-dependent identifiers.
 *----------------------------------------------------------------------*/

typedef_name:
	/* identifier */
	TYPEDEF_NAME { $$ = prepend_prodrule($1,101) ; }
	;

namespace_name:
	original_namespace_name { $$ = prepend_prodrule($1,201) ; }
	;

original_namespace_name:
	/* identifier */
	NAMESPACE_NAME { $$ = prepend_prodrule($1,301) ; }
	;

class_name:
	/* identifier */
	CLASS_NAME { $$ = prepend_prodrule($1,401) ; }
	| template_id { $$ = prepend_prodrule($1,402) ; }
	;

enum_name:
	/* identifier */
	ENUM_NAME { $$ = prepend_prodrule($1,501) ; }
	;

template_name:
	/* identifier */
	TEMPLATE_NAME { $$ = prepend_prodrule($1,601) ; }
	;

/*----------------------------------------------------------------------
 * Lexical elements.
 *----------------------------------------------------------------------*/

identifier:
	IDENTIFIER { $$ = prepend_prodrule($1,701) ; }
	;

literal:
	integer_literal { $$ = prepend_prodrule($1,801) ; }
	| character_literal { $$ = prepend_prodrule($1,802) ; }
	| floating_literal { $$ = prepend_prodrule($1,803) ; }
	| string_literal { $$ = prepend_prodrule($1,804) ; }
	| boolean_literal { $$ = prepend_prodrule($1,805) ; }
	;

integer_literal:
	INTEGER { $$ = prepend_prodrule($1,901) ; }
	;

character_literal:
	CHARACTER { $$ = prepend_prodrule($1,1001) ; }
	;

floating_literal:
	FLOATING { $$ = prepend_prodrule($1,1101) ; }
	;

string_literal:
	STRING { $$ = prepend_prodrule($1,1201) ; }
	;

boolean_literal:
	TRUE { $$ = prepend_prodrule($1,1301) ; }
	| FALSE { $$ = prepend_prodrule($1,1302) ; }
	;

/*----------------------------------------------------------------------
 * Translation unit.
 *----------------------------------------------------------------------*/

translation_unit:
	declaration_seq_opt { $$ = prepend_prodrule($1,1401) ; root = $$; }
	;

/*----------------------------------------------------------------------
 * Expressions.
 *----------------------------------------------------------------------*/

primary_expression:
	literal { $$ = prepend_prodrule($1,1501) ; }
	| THIS { $$ = prepend_prodrule($1,1502) ; }
	| '(' expression ')' { $$ = alcnode(1503,3,$1,$2,$3); }
	| id_expression { $$ = prepend_prodrule($1,1504) ; }
	;

id_expression:
	unqualified_id { $$ = prepend_prodrule($1,1601) ; }
	| qualified_id { $$ = prepend_prodrule($1,1602) ; }
	;

unqualified_id:
	identifier { $$ = prepend_prodrule($1,1701) ; }
	| operator_function_id { $$ = prepend_prodrule($1,1702) ; }
	| conversion_function_id { $$ = prepend_prodrule($1,1703) ; }
	| '~' class_name { $$ = alcnode(1704,2,$1,$2); }
	;

qualified_id:
	nested_name_specifier unqualified_id { $$ = alcnode(1801,2,$1,$2); }
	| nested_name_specifier TEMPLATE unqualified_id { $$ = alcnode(1802,3,$1,$2,$3); }
	;

nested_name_specifier:
	class_name COLONCOLON nested_name_specifier { $$ = alcnode(1901,3,$1,$2,$3); }
	| namespace_name COLONCOLON nested_name_specifier { $$ = alcnode(1902,3,$1,$2,$3); }
	| class_name COLONCOLON { $$ = alcnode(1903,2,$1,$2); }
	| namespace_name COLONCOLON { $$ = alcnode(1904,2,$1,$2); }
	;

postfix_expression:
	primary_expression { $$ = prepend_prodrule($1,2001) ; }
	| postfix_expression '[' expression ']' { $$ = alcnode(2002,4,$1,$2,$3,$4); }
	| postfix_expression '(' expression_list_opt ')' { $$ = alcnode(2003,4,$1,$2,$3,$4); }
	| postfix_expression '.' TEMPLATE COLONCOLON id_expression { $$ = alcnode(2004,5,$1,$2,$3,$4,$5); }
	| postfix_expression '.' TEMPLATE id_expression { $$ = alcnode(2005,4,$1,$2,$3,$4); }
	| postfix_expression '.' COLONCOLON id_expression { $$ = alcnode(2006,4,$1,$2,$3,$4); }
	| postfix_expression '.' id_expression { $$ = alcnode(2007,3,$1,$2,$3); }
	| postfix_expression ARROW TEMPLATE COLONCOLON id_expression { $$ = alcnode(2008,5,$1,$2,$3,$4,$5); }
	| postfix_expression ARROW TEMPLATE id_expression { $$ = alcnode(2009,4,$1,$2,$3,$4); }
	| postfix_expression ARROW COLONCOLON id_expression { $$ = alcnode(2010,4,$1,$2,$3,$4); }
	| postfix_expression ARROW id_expression { $$ = alcnode(2011,3,$1,$2,$3); }
	| postfix_expression PLUSPLUS { $$ = alcnode(2011,2,$1,$2); }
	| postfix_expression MINUSMINUS { $$ = alcnode(2012,2,$1,$2); }
	| DYNAMIC_CAST '<' type_id '>' '(' expression ')' { $$ = alcnode(2013,7,$1,$2,$3,$4,$5,$6,$7); }
	| STATIC_CAST '<' type_id '>' '(' expression ')' { $$ = alcnode(2014,7,$1,$2,$3,$4,$5,$6,$7); }
	| REINTERPRET_CAST '<' type_id '>' '(' expression ')' { $$ = alcnode(2015,7,$1,$2,$3,$4,$5,$6,$7); }
	| CONST_CAST '<' type_id '>' '(' expression ')' { $$ = alcnode(2016,7,$1,$2,$3,$4,$5,$6,$7); }
	| TYPEID '(' expression ')' { $$ = alcnode(2017,4,$1,$2,$3,$4); }
	| TYPEID '(' type_id ')' { $$ = alcnode(2018,4,$1,$2,$3,$4); }
	;

expression_list:
	assignment_expression { $$ = prepend_prodrule($1,2101) ; }
	| expression_list ',' assignment_expression { $$ = alcnode(2102,3,$1,$2,$3); }
	;

unary_expression:
	postfix_expression { $$ = prepend_prodrule($1,2201) ; }
	| PLUSPLUS cast_expression { $$ = alcnode(2202,2,$1,$2); }
	| MINUSMINUS cast_expression { $$ = alcnode(2203,2,$1,$2); }
	| '*' cast_expression { $$ = alcnode(2204,2,$1,$2); }
	| '&' cast_expression { $$ = alcnode(2205,2,$1,$2); }
	| unary_operator cast_expression { $$ = alcnode(2206,2,$1,$2); }
	| SIZEOF unary_expression { $$ = alcnode(2207,2,$1,$2); }
	| SIZEOF '(' type_id ')' { $$ = alcnode(2208,4,$1,$2,$3,$4); }
	| new_expression { $$ = prepend_prodrule($1,2209) ; }
	| delete_expression { $$ = prepend_prodrule($1,2210) ; }
	;

unary_operator:
	  '+' { $$ = prepend_prodrule($1,2201) ; }
	| '-' { $$ = prepend_prodrule($1,2202) ; }
	| '!' { $$ = prepend_prodrule($1,2203) ; }
	| '~' { $$ = prepend_prodrule($1,2204) ; }
	;

new_expression:
	  NEW new_placement_opt new_type_id new_initializer_opt { $$ = alcnode(2501,4,$1,$2,$3,$4); }
	| COLONCOLON NEW new_placement_opt new_type_id new_initializer_opt { $$ = alcnode(2502,5,$1,$2,$3,$4,$5); }
	| NEW new_placement_opt '(' type_id ')' new_initializer_opt { $$ = alcnode(2503,6,$1,$2,$3,$4,$5,$6); }
	| COLONCOLON NEW new_placement_opt '(' type_id ')' new_initializer_opt { $$ = alcnode(2504,7,$1,$2,$3,$4,$5,$6,$7); }
	;

new_placement:
	'(' expression_list ')' { $$ = alcnode(2501,3,$1,$2,$3); }
	;

new_type_id:
	type_specifier_seq new_declarator_opt { $$ = alcnode(2601,2,$1,$2); }
	;

new_declarator:
	ptr_operator new_declarator_opt { $$ = alcnode(2701,2,$1,$2); }
	| direct_new_declarator { $$ = prepend_prodrule($1,2702) ; }
	;

direct_new_declarator:
	'[' expression ']' { $$ = alcnode(2801,3,$1,$2,$3); }
	| direct_new_declarator '[' constant_expression ']'  { $$ = alcnode(2802,4,$1,$2,$3,$4); }
	;

new_initializer:
	'(' expression_list_opt ')' { $$ = alcnode(2901,3,$1,$2,$3); }
	;

delete_expression:
	  DELETE cast_expression { $$ = alcnode(3001,2,$1,$2); }
	| COLONCOLON DELETE cast_expression { $$ = alcnode(3002,3,$1,$2,$3); }
	| DELETE '[' ']' cast_expression { $$ = alcnode(3003,4,$1,$2,$3,$4); }
	| COLONCOLON DELETE '[' ']' cast_expression { $$ = alcnode(3004,5,$1,$2,$3,$4,$5); }
	;

cast_expression:
	unary_expression { $$ = prepend_prodrule($1,3101) ; }
	| '(' type_id ')' cast_expression { $$ = alcnode(3102,4,$1,$2,$3,$4); }
	;

pm_expression:
	cast_expression { $$ = prepend_prodrule($1,3201) ; }
	| pm_expression DOTSTAR cast_expression { $$ = alcnode(3202,3,$1,$2,$3); }
	| pm_expression ARROWSTAR cast_expression { $$ = alcnode(3203,3,$1,$2,$3); }
	;

multiplicative_expression:
	pm_expression { $$ = prepend_prodrule($1,3301) ; }
	| multiplicative_expression '*' pm_expression { $$ = alcnode(3302,3,$1,$2,$3); }
	| multiplicative_expression '/' pm_expression { $$ = alcnode(3303,3,$1,$2,$3); }
	| multiplicative_expression '%' pm_expression { $$ = alcnode(3304,3,$1,$2,$3); }
	;

additive_expression:
	multiplicative_expression { $$ = prepend_prodrule($1,3401) ; }
	| additive_expression '+' multiplicative_expression { $$ = alcnode(3402,3,$1,$2,$3); }
	| additive_expression '-' multiplicative_expression { $$ = alcnode(3403,3,$1,$2,$3); }
	;

shift_expression:
	additive_expression { $$ = prepend_prodrule($1,3501) ; }
	| shift_expression SL additive_expression { $$ = alcnode(3502,3,$1,$2,$3); }
	| shift_expression SR additive_expression { $$ = alcnode(3503,3,$1,$2,$3); }
	;

relational_expression:
	shift_expression { $$ = prepend_prodrule($1,3601) ; }
	| relational_expression '<' shift_expression { $$ = alcnode(3602,3,$1,$2,$3); }
	| relational_expression '>' shift_expression { $$ = alcnode(3603,3,$1,$2,$3); }
	| relational_expression LTEQ shift_expression { $$ = alcnode(3604,3,$1,$2,$3); }
	| relational_expression GTEQ shift_expression { $$ = alcnode(3605,3,$1,$2,$3); }
	;

equality_expression:
	relational_expression { $$ = prepend_prodrule($1,3701) ; }
	| equality_expression EQ relational_expression { $$ = alcnode(3702,3,$1,$2,$3); }
	| equality_expression NOTEQ relational_expression { $$ = alcnode(3703,3,$1,$2,$3); }
	;

and_expression:
	equality_expression { $$ = prepend_prodrule($1,3801) ; }
	| and_expression '&' equality_expression { $$ = alcnode(3802,3,$1,$2,$3); }
	;

exclusive_or_expression:
	and_expression { $$ = prepend_prodrule($1,3901) ; }
	| exclusive_or_expression '^' and_expression { $$ = alcnode(3902,3,$1,$2,$3); }
	;

inclusive_or_expression:
	exclusive_or_expression { $$ = prepend_prodrule($1,4001) ; }
	| inclusive_or_expression '|' exclusive_or_expression { $$ = alcnode(4002,3,$1,$2,$3); }
	;

logical_and_expression:
	inclusive_or_expression { $$ = prepend_prodrule($1,4101) ; }
	| logical_and_expression ANDAND inclusive_or_expression { $$ = alcnode(4102,3,$1,$2,$3); }
	;

logical_or_expression:
	logical_and_expression { $$ = prepend_prodrule($1,4201) ; }
	| logical_or_expression OROR logical_and_expression { $$ = alcnode(4202,3,$1,$2,$3); }
	;

conditional_expression:
	logical_or_expression { $$ = prepend_prodrule($1,4301) ; }
	| logical_or_expression  '?' expression ':' assignment_expression { $$ = alcnode(4302,5,$1,$2,$3,$4,$5); }
	;

assignment_expression:
	conditional_expression { $$ = prepend_prodrule($1,4401) ; }
	| logical_or_expression assignment_operator assignment_expression { $$ = alcnode(4402,3,$1,$2,$3); }
	| throw_expression { $$ = prepend_prodrule($1,4403) ; }
	;

assignment_operator:
	'=' { $$ = prepend_prodrule($1,4501) ; }
	| MULEQ { $$ = prepend_prodrule($1,4502) ; }
	| DIVEQ { $$ = prepend_prodrule($1,4503) ; }
	| MODEQ { $$ = prepend_prodrule($1,4504) ; }
	| ADDEQ { $$ = prepend_prodrule($1,4505) ; }
	| SUBEQ { $$ = prepend_prodrule($1,4506) ; }
	| SREQ { $$ = prepend_prodrule($1,4507) ; }
	| SLEQ { $$ = prepend_prodrule($1,4508) ; }
	| ANDEQ { $$ = prepend_prodrule($1,4509) ; }
	| XOREQ { $$ = prepend_prodrule($1,4510) ; }
	| OREQ { $$ = prepend_prodrule($1,4511) ; }
	;

expression:
	assignment_expression { $$ = prepend_prodrule($1,4601) ; }
	| expression ',' assignment_expression { $$ = alcnode(4602,3,$1,$2,$3); }
	;

constant_expression:
	conditional_expression { $$ = prepend_prodrule($1,4701) ; }
	;

/*----------------------------------------------------------------------
 * Statements.
 *----------------------------------------------------------------------*/

statement:
	labeled_statement { $$ = prepend_prodrule($1,4801) ; }
	| expression_statement { $$ = prepend_prodrule($1,4802) ; }
	| compound_statement { $$ = prepend_prodrule($1,4803) ; }
	| selection_statement { $$ = prepend_prodrule($1,4804) ; }
	| iteration_statement { $$ = prepend_prodrule($1,4805) ; }
	| jump_statement { $$ = prepend_prodrule($1,4806) ; }
	| declaration_statement { $$ = prepend_prodrule($1,4807) ; }
	| try_block { $$ = prepend_prodrule($1,4808) ; }
	;

labeled_statement:
	identifier ':' statement { $$ = alcnode(4901,3,$1,$2,$3); }
	| CASE constant_expression ':' statement { $$ = alcnode(4902,3,$1,$2,$3); }
	| DEFAULT ':' statement { $$ = alcnode(4903,3,$1,$2,$3); }
	;

expression_statement:
	expression_opt ';' { $$ = alcnode(5001,2,$1,$2); }
	;

compound_statement:
	'{' statement_seq_opt '}' { $$ = alcnode(5101,3,$1,$2,$3); }
	;

statement_seq:
	statement { $$ = prepend_prodrule($1,5201) ; }
	| statement_seq statement { $$ = alcnode(5202,2,$1,$2); }
	;

selection_statement:
	IF '(' condition ')' statement { $$ = alcnode(5301,5,$1,$2,$3,$4,$5); }
	| IF '(' condition ')' statement ELSE statement { $$ = alcnode(5302,7,$1,$2,$3,$4,$5,$6,$7); }
	| SWITCH '(' condition ')' statement { $$ = alcnode(5303,5,$1,$2,$3,$4,$5); }
	;

condition:
	expression { $$ = prepend_prodrule($1,5401) ; }
	| type_specifier_seq declarator '=' assignment_expression { $$ = alcnode(5402,4,$1,$2,$3,$4); }
	;

iteration_statement:
	WHILE '(' condition ')' statement { $$ = alcnode(5501,5,$1,$2,$3,$4,$5); }
	| DO statement WHILE '(' expression ')' ';' { $$ = alcnode(5502,6,$1,$2,$3,$4,$5,$6); }
	| FOR '(' for_init_statement condition_opt ';' expression_opt ')' statement { $$ = alcnode(5503,8,$1,$2,$3,$4,$5,$6,$7,$8); }
	;

for_init_statement:
	expression_statement { $$ = prepend_prodrule($1,5601) ; }
	| simple_declaration { $$ = prepend_prodrule($1,5602) ; }
	;

jump_statement:
	BREAK ';' { $$ = alcnode(5701,2,$1,$2); }
	| CONTINUE ';' { $$ = alcnode(5702,2,$1,$2); }
	| RETURN expression_opt ';' { $$ = alcnode(5703,3,$1,$2,$3); }
	| GOTO identifier ';' { $$ = alcnode(5704,3,$1,$2,$3); }
	;

declaration_statement:
	block_declaration { $$ = prepend_prodrule($1,5801) ; }
	;

/*----------------------------------------------------------------------
 * Declarations.
 *----------------------------------------------------------------------*/

declaration_seq:
	declaration { $$ = prepend_prodrule($1,5901) ; }
	| declaration_seq declaration { $$ = alcnode(5902,2,$1,$2); }
	;

declaration:
	block_declaration { $$ = prepend_prodrule($1,6001) ; }
	| function_definition { $$ = prepend_prodrule($1,6002) ; }
	| template_declaration { $$ = prepend_prodrule($1,6003) ; }
	| explicit_instantiation { $$ = prepend_prodrule($1,6004) ; }
	| explicit_specialization { $$ = prepend_prodrule($1,6005) ; }
	| linkage_specification { $$ = prepend_prodrule($1,6006) ; }
	| namespace_definition { $$ = prepend_prodrule($1,6007) ; }
	;

block_declaration:
	simple_declaration { $$ = prepend_prodrule($1,6101) ; }
	| asm_definition { $$ = prepend_prodrule($1,6102) ; }
	| namespace_alias_definition { $$ = prepend_prodrule($1,6103) ; }
	| using_declaration { $$ = prepend_prodrule($1,6104) ; }
	| using_directive { $$ = prepend_prodrule($1,6105) ; }
	;

simple_declaration:
	  decl_specifier_seq init_declarator_list ';' { $$ = alcnode(6201,3,$1,$2,$3); }
	|  decl_specifier_seq ';' { $$ = alcnode(6202,2,$1,$2); }
	;

decl_specifier:
	storage_class_specifier { $$ = prepend_prodrule($1,6301) ; }
	| type_specifier { $$ = prepend_prodrule($1,6302) ; }
	| function_specifier { $$ = prepend_prodrule($1,6303) ; }
	| FRIEND { $$ = prepend_prodrule($1,6304) ; }
	| TYPEDEF { $$ = prepend_prodrule($1,6305) ; }
	;

decl_specifier_seq:
	  decl_specifier { $$ = prepend_prodrule($1,6401) ; }
	| decl_specifier_seq decl_specifier { $$ = alcnode(6402,2,$1,$2); }
	;

storage_class_specifier:
	AUTO { $$ = prepend_prodrule($1,6501) ; }
	| REGISTER { $$ = prepend_prodrule($1,6502) ; }
	| STATIC { $$ = prepend_prodrule($1,6503) ; }
	| EXTERN { $$ = prepend_prodrule($1,6504) ; }
	| MUTABLE { $$ = prepend_prodrule($1,6505) ; }
	;

function_specifier:
	INLINE { $$ = prepend_prodrule($1,6601) ; }
	| VIRTUAL { $$ = prepend_prodrule($1,6602) ; }
	| EXPLICIT { $$ = prepend_prodrule($1,6603) ; }
	;

type_specifier:
	simple_type_specifier { $$ = prepend_prodrule($1,6701) ; }
	| class_specifier { $$ = prepend_prodrule($1,6702) ; }
	| enum_specifier { $$ = prepend_prodrule($1,6703) ; }
	| elaborated_type_specifier { $$ = prepend_prodrule($1,6704) ; }
	| cv_qualifier { $$ = prepend_prodrule($1,6705) ; }
	;

simple_type_specifier:
	  type_name { $$ = prepend_prodrule($1,6801) ; }
	| nested_name_specifier type_name { $$ = alcnode(6802,2,$1,$2); }
	| COLONCOLON nested_name_specifier_opt type_name { $$ = alcnode(6803,3,$1,$2,$3); }
	| CHAR { $$ = prepend_prodrule($1,6804) ; }
	| WCHAR_T { $$ = prepend_prodrule($1,6805) ; }
	| BOOL { $$ = prepend_prodrule($1,6806) ; }
	| SHORT { $$ = prepend_prodrule($1,6807) ; }
	| INT { $$ = prepend_prodrule($1,6808) ; }
	| LONG { $$ = prepend_prodrule($1,6809) ; }
	| SIGNED { $$ = prepend_prodrule($1,6810) ; }
	| UNSIGNED { $$ = prepend_prodrule($1,6811) ; }
	| FLOAT { $$ = prepend_prodrule($1,6812) ; }
	| DOUBLE { $$ = prepend_prodrule($1,6813) ; }
	| VOID { $$ = prepend_prodrule($1,6814) ; }
	;

type_name:
	class_name { $$ = prepend_prodrule($1,6901) ; }
	| enum_name { $$ = prepend_prodrule($1,6902) ; }
	| typedef_name { $$ = prepend_prodrule($1,6903) ; }
	;

elaborated_type_specifier:
	  class_key COLONCOLON nested_name_specifier identifier { $$ = alcnode(7001,4,$1,$2,$3,$4); }
	| class_key COLONCOLON identifier { $$ = alcnode(7002,3,$1,$2,$3); }
	| ENUM COLONCOLON nested_name_specifier identifier { $$ = alcnode(7003,4,$1,$2,$3,$4); }
	| ENUM COLONCOLON identifier { $$ = alcnode(7004,3,$1,$2,$3); }
	| ENUM nested_name_specifier identifier { $$ = alcnode(7005,3,$1,$2,$3); }
	| TYPENAME COLONCOLON_opt nested_name_specifier identifier { $$ = alcnode(7006,4,$1,$2,$3,$4); }
	| TYPENAME COLONCOLON_opt nested_name_specifier identifier '<' template_argument_list '>' { $$ = alcnode(7007,7,$1,$2,$3,$4,$5,$6,$7); }
	;

/*
enum_name:
	identifier { $$ = prepend_prodrule($1,7101) ; }
	;
*/

enum_specifier:
	ENUM identifier '{' enumerator_list_opt '}' { $$ = alcnode(7201,5,$1,$2,$3,$4,$5); }
	;

enumerator_list:
	enumerator_definition { $$ = prepend_prodrule($1,7301) ; }
	| enumerator_list ',' enumerator_definition { $$ = alcnode(7302,3,$1,$2,$3); }
	;

enumerator_definition:
	enumerator { $$ = prepend_prodrule($1,7401) ; }
	| enumerator '=' constant_expression { $$ = alcnode(7402,3,$1,$2,$3); }
	;

enumerator:
	identifier { $$ = prepend_prodrule($1,7501) ; }
	;

/*
namespace_name:
	original_namespace_name { $$ = $1; }
	| namespace_alias { $$ = $1; }
	;

original_namespace_name:
	identifier { $$ = $1; }
	;
*/

namespace_definition:
	named_namespace_definition { $$ = $1; }
	| unnamed_namespace_definition { $$ = $1; }
	;

named_namespace_definition:
	original_namespace_definition { $$ = $1; }
	| extension_namespace_definition { $$ = $1; }
	;

original_namespace_definition:
	NAMESPACE identifier '{' namespace_body '}' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	;

extension_namespace_definition:
	NAMESPACE original_namespace_name '{' namespace_body '}' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	;

unnamed_namespace_definition:
	NAMESPACE '{' namespace_body '}' { $$ = alcnode(101,4,$1,$2,$3,$4); }
	;

namespace_body:
	declaration_seq_opt { $$ = $1; }
	;

/*
namespace_alias:
	identifier { $$ = $1; }
	;
*/

namespace_alias_definition:
	NAMESPACE identifier '=' qualified_namespace_specifier ';' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	;

qualified_namespace_specifier:
	  COLONCOLON nested_name_specifier namespace_name { $$ = alcnode(101,3,$1,$2,$3); }
	| COLONCOLON namespace_name { $$ = alcnode(101,2,$1,$2); }
	| nested_name_specifier namespace_name { $$ = alcnode(101,2,$1,$2); }
	| namespace_name { $$ = $1; }
	;

using_declaration:
	  USING TYPENAME COLONCOLON nested_name_specifier unqualified_id ';' { $$ = alcnode(101,6,$1,$2,$3,$4,$5,$6); }
	| USING TYPENAME nested_name_specifier unqualified_id ';' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	| USING COLONCOLON nested_name_specifier unqualified_id ';' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	| USING nested_name_specifier unqualified_id ';' { $$ = alcnode(101,4,$1,$2,$3,$4); }
	| USING COLONCOLON unqualified_id ';' { $$ = alcnode(101,4,$1,$2,$3,$4); }
	;

using_directive:
	USING NAMESPACE COLONCOLON nested_name_specifier namespace_name ';' { $$ = alcnode(101,6,$1,$2,$3,$4,$5,$6); }
	| USING NAMESPACE COLONCOLON namespace_name ';' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	| USING NAMESPACE nested_name_specifier namespace_name ';' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	| USING NAMESPACE namespace_name ';' { $$ = alcnode(101,4,$1,$2,$3,$4); }
	;

asm_definition:
	ASM '(' string_literal ')' ';' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	;

linkage_specification:
	EXTERN string_literal '{' declaration_seq_opt '}' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	| EXTERN string_literal declaration { $$ = alcnode(101,3,$1,$2,$3); }
	;

/*----------------------------------------------------------------------
 * Declarators.
 *----------------------------------------------------------------------*/

init_declarator_list:
	init_declarator { $$ = prepend_prodrule($1,7601) ; }
	| init_declarator_list ',' init_declarator { $$ = alcnode(7602,3,$1,$2,$3); }
	;

init_declarator:
	declarator initializer_opt { $$ = alcnode(7701,2,$1,$2); }
	;

declarator:
	direct_declarator { $$ = prepend_prodrule($1,7801) ; }
	| ptr_operator declarator { $$ = alcnode(7802,2,$1,$2); }
	;

direct_declarator:
	  declarator_id { $$ = prepend_prodrule($1,7901) ; }
	| direct_declarator '('parameter_declaration_clause ')' cv_qualifier_seq exception_specification { $$ = alcnode(7902,6,$1,$2,$3,$4,$5,$6); }
	| direct_declarator '('parameter_declaration_clause ')' cv_qualifier_seq { $$ = alcnode(7903,5,$1,$2,$3,$4,$5); }
	| direct_declarator '('parameter_declaration_clause ')' exception_specification { $$ = alcnode(7904,5,$1,$2,$3,$4,$5); }
	| direct_declarator '('parameter_declaration_clause ')' { $$ = alcnode(7905,4,$1,$2,$3,$4); }
	| direct_declarator '[' constant_expression_opt ']' { $$ = alcnode(7906,4,$1,$2,$3,$4); }
	| CLASS_NAME '('parameter_declaration_clause ')' { $$ = alcnode(7907,4,$1,$2,$3,$4); }
	| CLASS_NAME COLONCOLON declarator_id '('parameter_declaration_clause ')' { $$ = alcnode(7908,6,$1,$2,$3,$4,$5,$6); }
	| CLASS_NAME COLONCOLON CLASS_NAME '('parameter_declaration_clause ')' { $$ = alcnode(7909,6,$1,$2,$3,$4,$5,$6); } 
    | '(' declarator ')' { $$ = alcnode(7910,3,$1,$2,$3); }
	;

ptr_operator:
	'*' { $$ = prepend_prodrule($1,8001) ; }
	| '*' cv_qualifier_seq { $$ = alcnode(8001,2,$1,$2); }
	| '&' { $$ = prepend_prodrule($1,8002) ; }
	| nested_name_specifier '*' { $$ = alcnode(8002,2,$1,$2); }
	| nested_name_specifier '*' cv_qualifier_seq { $$ = alcnode(8003,3,$1,$2,$3); }
	| COLONCOLON nested_name_specifier '*' { $$ = alcnode(8004,3,$1,$2,$3); }
	| COLONCOLON nested_name_specifier '*' cv_qualifier_seq { $$ = alcnode(8005,4,$1,$2,$3,$4); }
	;

cv_qualifier_seq:
	cv_qualifier { $$ = prepend_prodrule($1,8102) ; }
	| cv_qualifier cv_qualifier_seq { $$ = alcnode(8101,2,$1,$2); }
	;

cv_qualifier:
	CONST { $$ = prepend_prodrule($1,8201) ; }
	| VOLATILE { $$ = prepend_prodrule($1,8202) ; }
	;

declarator_id:
	  id_expression { $$ = prepend_prodrule($1,8301) ; }
	| COLONCOLON id_expression { $$ = alcnode(8302,2,$1,$2); }
	| COLONCOLON nested_name_specifier type_name { $$ = alcnode(8303,3,$1,$2,$3); }
	| COLONCOLON type_name { $$ = alcnode(8304,2,$1,$2); }
	;

type_id:
	type_specifier_seq abstract_declarator_opt { $$ = alcnode(8401,2,$1,$2); }
	;

type_specifier_seq:
	type_specifier type_specifier_seq_opt { $$ = alcnode(8501,2,$1,$2); }
	;

abstract_declarator:
	ptr_operator abstract_declarator_opt { $$ = alcnode(8601,2,$1,$2); }
	| direct_abstract_declarator { $$ = prepend_prodrule($1,8602) ; }
	;

direct_abstract_declarator:
	  direct_abstract_declarator_opt '(' parameter_declaration_clause ')' cv_qualifier_seq exception_specification { $$ = alcnode(8602,6,$1,$2,$3,$4,$5,$6); }
	| direct_abstract_declarator_opt '(' parameter_declaration_clause ')' cv_qualifier_seq { $$ = alcnode(8603,5,$1,$2,$3,$4,$5); }
	| direct_abstract_declarator_opt '(' parameter_declaration_clause ')' exception_specification { $$ = alcnode(8604,5,$1,$2,$3,$4,$5); }
	| direct_abstract_declarator_opt '(' parameter_declaration_clause ')' { $$ = alcnode(8605,4,$1,$2,$3,$4); }
	| direct_abstract_declarator_opt '[' constant_expression_opt ']' { $$ = alcnode(8606,4,$1,$2,$3,$4); }
	| '(' abstract_declarator ')' { $$ = alcnode(8607,3,$1,$2,$3); }
	;

parameter_declaration_clause:
	  parameter_declaration_list ELLIPSIS { $$ = alcnode(8701,2,$1,$2); }
	| parameter_declaration_list { $$ = prepend_prodrule($1,8702) ; }
	| ELLIPSIS { $$ = prepend_prodrule($1,8703) ; }
	| parameter_declaration_list ',' ELLIPSIS { $$ = alcnode(8704,3,$1,$2,$3); }
	| { $$ = NULL ; }
	;

parameter_declaration_list:
	parameter_declaration { $$ = prepend_prodrule($1,8802) ; }
	| parameter_declaration_list ',' parameter_declaration { $$ = alcnode(8801,3,$1,$2,$3); }
	;

parameter_declaration:
	decl_specifier_seq declarator { $$ = alcnode(8901,2,$1,$2); }
	| decl_specifier_seq declarator '=' assignment_expression { $$ = alcnode(8902,4,$1,$2,$3,$4); }
	| decl_specifier_seq abstract_declarator_opt { $$ = alcnode(8903,2,$1,$2); }
	| decl_specifier_seq abstract_declarator_opt '=' assignment_expression { $$ = alcnode(8904,4,$1,$2,$3,$4); }
	;

function_definition:
	  declarator ctor_initializer_opt function_body { $$ = alcnode(9001,3,$1,$2,$3); }
	| decl_specifier_seq declarator ctor_initializer_opt function_body { $$ = alcnode(9002,4,$1,$2,$3,$4); }
	| declarator function_try_block { $$ = alcnode(9003,2,$1,$2); }
	| decl_specifier_seq declarator function_try_block { $$ = alcnode(9004,3,$1,$2,$3); }
	;

function_body:
	compound_statement { $$ = prepend_prodrule($1,9101) ; }
	;

initializer:
	'=' initializer_clause { $$ = alcnode(9201,2,$1,$2); }
	| '(' expression_list ')' { $$ = alcnode(9202,3,$1,$2,$3); }
	;

initializer_clause:
	assignment_expression { $$ = prepend_prodrule($1,9301) ; }
	| '{' initializer_list COMMA_opt '}' { $$ = alcnode(9302,4,$1,$2,$3,$4); }
	| '{' '}' { $$ = alcnode(9303,2,$1,$2); }
	;

initializer_list:
	initializer_clause { $$ = prepend_prodrule($1,9401) ; }
	| initializer_list ',' initializer_clause { $$ = alcnode(9402,3,$1,$2,$3); }
	;

/*----------------------------------------------------------------------
 * Classes.
 *----------------------------------------------------------------------*/

class_specifier:
	class_head '{' member_specification_opt '}' { $$ = alcnode(9501,4,$1,$2,$3,$4); }
	;

class_head:
	  class_key identifier { insert_name($2->t,265); $$ = alcnode(9601,2,$1,$2); }
	| class_key class_name { yyerror("Doubly defined type"); exit(1); }
	| class_key identifier base_clause { $$ = alcnode(9602,3,$1,$2,$3); }
	| class_key class_name base_clause { yyerror("Doubly defined type"); exit(1); }
	| class_key nested_name_specifier identifier { $$ = alcnode(9603,3,$1,$2,$3); }
	| class_key nested_name_specifier class_name { yyerror("Doubly defined type"); exit(1); }
	| class_key nested_name_specifier identifier base_clause { $$ = alcnode(9604,4,$1,$2,$3,$4); }
	| class_key nested_name_specifier class_name base_clause { yyerror("Doubly defined type"); exit(1); }
	;

class_key:
	CLASS { $$ = prepend_prodrule($1,9701) ;}
	| STRUCT { $$ = prepend_prodrule($1,9702) ;}
	| UNION { $$ = prepend_prodrule($1,9703) ; }
	;

member_specification:
	member_declaration member_specification_opt { $$ = alcnode(9801,2,$1,$2); }
	| access_specifier ':' member_specification_opt { $$ = alcnode(9802,3,$1,$2,$3); }
	;

member_declaration:
	  decl_specifier_seq member_declarator_list ';' { $$ = alcnode(9901,3,$1,$2,$3); }
	| decl_specifier_seq ';' { $$ = alcnode(9902,2,$1,$2); }
	| member_declarator_list ';' { $$ = alcnode(9903,2,$1,$2); }
	| ';' { $$ = prepend_prodrule($1,9904) ; }
	| function_definition SEMICOLON_opt { $$ = alcnode(9905,2,$1,$2); }
	| qualified_id ';' { $$ = alcnode(9906,2,$1,$2); }
	| using_declaration { $$ = prepend_prodrule($1,9907) ; }
	| template_declaration { $$ = prepend_prodrule($1,9908) ; }
	;

member_declarator_list:
	member_declarator { $$ = prepend_prodrule($1,10001) ; }
	| member_declarator_list ',' member_declarator { $$ = alcnode(10002,3,$1,$2,$3); }
	;

member_declarator:
	| declarator { $$ = prepend_prodrule($1,10101) ; }
	| declarator pure_specifier { $$ = alcnode(10102,2,$1,$2); }
	| declarator constant_initializer { $$ = alcnode(10103,2,$1,$2); }
	| identifier ':' constant_expression { $$ = alcnode(10104,3,$1,$2,$3); }
	;

/*
 * This rule need a hack for working around the ``= 0'' pure specifier.
 * 0 is returned as an ``INTEGER'' by the lexical analyzer but in this
 * context is different.
 */
pure_specifier:
	'=' '0' { $$ = alcnode(101,2,$1,$2); }
	;

constant_initializer:
	'=' constant_expression { $$ = alcnode(10201,2,$1,$2); }
	;

/*----------------------------------------------------------------------
 * Derived classes.
 *----------------------------------------------------------------------*/

base_clause:
	':' base_specifier_list { $$ = alcnode(10301,2,$1,$2); }
	;

base_specifier_list:
	base_specifier { $$ = prepend_prodrule($1,10401) ; }
	| base_specifier_list ',' base_specifier { $$ = alcnode(10402,3,$1,$2,$3); }
	;

base_specifier:
	  COLONCOLON nested_name_specifier class_name { $$ = alcnode(10501,3,$1,$2,$3); }
	| COLONCOLON class_name { $$ = alcnode(10502,2,$1,$2); }
	| nested_name_specifier class_name { $$ = alcnode(10503,2,$1,$2); }
	| class_name { $$ = prepend_prodrule($1,10504) ; }
	| VIRTUAL access_specifier COLONCOLON nested_name_specifier_opt class_name { $$ = alcnode(10505,5,$1,$2,$3,$4,$5); }
	| VIRTUAL access_specifier nested_name_specifier_opt class_name { $$ = alcnode(10506,4,$1,$2,$3,$4); }
	| VIRTUAL COLONCOLON nested_name_specifier_opt class_name { $$ = alcnode(10507,4,$1,$2,$3,$4); }
	| VIRTUAL nested_name_specifier_opt class_name { $$ = alcnode(10508,3,$1,$2,$3); }
	| access_specifier VIRTUAL COLONCOLON nested_name_specifier_opt class_name { $$ = alcnode(10509,5,$1,$2,$3,$4,$5); }
	| access_specifier VIRTUAL nested_name_specifier_opt class_name { $$ = alcnode(10510,4,$1,$2,$3,$4); }
	| access_specifier COLONCOLON nested_name_specifier_opt class_name { $$ = alcnode(10511,4,$1,$2,$3,$4); }
	| access_specifier nested_name_specifier_opt class_name { $$ = alcnode(10512,3,$1,$2,$3); }
	;

access_specifier:
	PRIVATE { $$ = prepend_prodrule($1,10601) ; }
	| PROTECTED { $$ = prepend_prodrule($1,10602) ; }
	| PUBLIC { $$ = prepend_prodrule($1,10603) ; }
	;

/*----------------------------------------------------------------------
 * Special member functions.
 *----------------------------------------------------------------------*/

conversion_function_id:
	OPERATOR conversion_type_id { $$ = alcnode(10701,2,$1,$2); }
	;

conversion_type_id:
	type_specifier_seq conversion_declarator_opt { $$ = alcnode(10801,2,$1,$2); }
	;

conversion_declarator:
	ptr_operator conversion_declarator_opt { $$ = alcnode(10901,2,$1,$2); }
	;

ctor_initializer:
	':' mem_initializer_list { $$ = alcnode(11001,2,$1,$2); }
	;

mem_initializer_list:
	mem_initializer { $$ = prepend_prodrule($1,11101) ; }
	| mem_initializer ',' mem_initializer_list { $$ = alcnode(11102,3,$1,$2,$3); }
	;

mem_initializer:
	mem_initializer_id '(' expression_list_opt ')' { $$ = alcnode(11201,4,$1,$2,$3,$4); }
	;

mem_initializer_id:
	  COLONCOLON nested_name_specifier class_name { $$ = alcnode(11301,3,$1,$2,$3); }
	| COLONCOLON class_name { $$ = alcnode(11302,2,$1,$2); }
	| nested_name_specifier class_name { $$ = alcnode(11303,2,$1,$2); }
	| class_name { $$ = prepend_prodrule($1,11304) ; }
	| identifier { $$ = prepend_prodrule($1,11305) ; }
	;

/*----------------------------------------------------------------------
 * Overloading.
 *----------------------------------------------------------------------*/

operator_function_id:
	OPERATOR operator { $$ = alcnode(11401,2,$1,$2); }
	;

operator:
	NEW { $$ = prepend_prodrule($1,11501) ; }
	| DELETE { $$ = prepend_prodrule($1,11502) ; }
	| NEW '[' ']' { $$ = alcnode(11503,3,$1,$2,$3); }
	| DELETE '[' ']' { $$ = alcnode(11504,3,$1,$2,$3); }
	| '+' { $$ = prepend_prodrule($1,11505) ; }
	| '_' { $$ = prepend_prodrule($1,11506) ; }
	| '*' { $$ = prepend_prodrule($1,11507) ; }
	| '/' { $$ = prepend_prodrule($1,11508) ; }
	| '%' { $$ = prepend_prodrule($1,11509) ; }
	| '^' { $$ = prepend_prodrule($1,11510) ; }
	| '&' { $$ = prepend_prodrule($1,11511) ; }
	| '|' { $$ = prepend_prodrule($1,11512) ; }
	| '~' { $$ = prepend_prodrule($1,11513) ; }
	| '!' { $$ = prepend_prodrule($1,11514) ; }
	| '=' { $$ = prepend_prodrule($1,11515) ; }
	| '<' { $$ = prepend_prodrule($1,11516) ; }
	| '>' { $$ = prepend_prodrule($1,11517) ; }
	| ADDEQ { $$ = prepend_prodrule($1,11518) ; }
	| SUBEQ { $$ = prepend_prodrule($1,11519) ; }
	| MULEQ { $$ = prepend_prodrule($1,11520) ; }
	| DIVEQ { $$ = prepend_prodrule($1,11521) ; }
	| MODEQ { $$ = prepend_prodrule($1,11522) ; }
	| XOREQ { $$ = prepend_prodrule($1,11523) ; }
	| ANDEQ { $$ = prepend_prodrule($1,11524) ; }
	| OREQ { $$ = prepend_prodrule($1,11525) ; }
	| SL { $$ = prepend_prodrule($1,11526) ; }
	| SR { $$ = prepend_prodrule($1,11527) ; }
	| SREQ { $$ = prepend_prodrule($1,11528) ; }
	| SLEQ { $$ = prepend_prodrule($1,11529) ; }
	| EQ { $$ = prepend_prodrule($1,11530) ; }
	| NOTEQ { $$ = prepend_prodrule($1,11531) ; }
	| LTEQ { $$ = prepend_prodrule($1,11532) ; }
	| GTEQ { $$ = prepend_prodrule($1,11533) ; }
	| ANDAND { $$ = prepend_prodrule($1,11534) ; }
	| OROR { $$ = prepend_prodrule($1,11535) ; }
	| PLUSPLUS { $$ = prepend_prodrule($1,11536) ; }
	| MINUSMINUS { $$ = prepend_prodrule($1,11537) ; }
	| ',' { $$ = prepend_prodrule($1,11538) ; }
	| ARROWSTAR { $$ = prepend_prodrule($1,11539) ; }
	| ARROW { $$ = prepend_prodrule($1,11540) ; }
	| '(' ')' { $$ = alcnode(11505,2,$1,$2); }
	| '[' ']' { $$ = alcnode(11506,2,$1,$2); }
	;

/*----------------------------------------------------------------------
 * Templates.
 *----------------------------------------------------------------------*/

template_declaration:
	EXPORT_opt TEMPLATE '<' template_parameter_list '>' declaration { $$ = alcnode(11601,6,$1,$2,$3,$4,$5,$6); }
	;

template_parameter_list:
	template_parameter { $$ = prepend_prodrule($1,11701) ; }
	| template_parameter_list ',' template_parameter { $$ = alcnode(11702,3,$1,$2,$3); }
	;

template_parameter:
	type_parameter { $$ = prepend_prodrule($1,11801) ; }
	| parameter_declaration { $$ = prepend_prodrule($1,11802) ; }
	;

type_parameter:
	  CLASS identifier { $$ = alcnode(11901,2,$1,$2); }
	| CLASS identifier '=' type_id { $$ = alcnode(11902,4,$1,$2,$3,$4); }
	| TYPENAME identifier { $$ = alcnode(11903,2,$1,$2); }
	| TYPENAME identifier '=' type_id { $$ = alcnode(11904,4,$1,$2,$3,$4); }
	| TEMPLATE '<' template_parameter_list '>' CLASS identifier { $$ = alcnode(11905,6,$1,$2,$3,$4,$5,$6); }
	| TEMPLATE '<' template_parameter_list '>' CLASS identifier '=' template_name { $$ = alcnode(11906,8,$1,$2,$3,$4,$5,$6,$7,$8); }
	;

template_id:
	template_name '<' template_argument_list '>' { $$ = alcnode(12001,4,$1,$2,$3,$4); }
	;

template_argument_list:
	template_argument { $$ = prepend_prodrule($1,12101) ; }
	| template_argument_list ',' template_argument { $$ = alcnode(12102,3,$1,$2,$3); }
	;

template_argument:
	assignment_expression { $$ = prepend_prodrule($1,12201) ; }
	| type_id { $$ = prepend_prodrule($1,12202) ; }
	| template_name { $$ = prepend_prodrule($1,12203) ; }
	;

explicit_instantiation:
	TEMPLATE declaration { $$ = alcnode(12301,2,$1,$2); }
	;

explicit_specialization:
	TEMPLATE '<' '>' declaration { $$ = alcnode(12401,4,$1,$2,$3,$4); }
	;

/*----------------------------------------------------------------------
 * Exception handling.
 *----------------------------------------------------------------------*/

try_block:
	TRY compound_statement handler_seq { $$ = alcnode(12501,3,$1,$2,$3); }
	;

function_try_block:
	TRY ctor_initializer_opt function_body handler_seq { $$ = alcnode(12601,4,$1,$2,$3,$4); }
	;

handler_seq:
	handler handler_seq_opt { $$ = alcnode(12701,2,$1,$2); }
	;

handler:
	CATCH '(' exception_declaration ')' compound_statement { $$ = alcnode(12801,5,$1,$2,$3,$4,$5); }
	;

exception_declaration:
	type_specifier_seq declarator { $$ = alcnode(12901,2,$1,$2); }
	| type_specifier_seq abstract_declarator { $$ = alcnode(12902,2,$1,$2); }
	| type_specifier_seq { $$ = prepend_prodrule($1,12903) ; }
	| ELLIPSIS { $$ = prepend_prodrule($1,12904) ; }
	;

throw_expression:
	THROW assignment_expression_opt { $$ = alcnode(13001,2,$1,$2); }
	;

exception_specification:
	THROW '(' type_id_list_opt ')' { $$ = alcnode(13101,4,$1,$2,$3,$4); }
	;

type_id_list:
	type_id { $$ = prepend_prodrule($1,13201) ; }
	| type_id_list ',' type_id { $$ = alcnode(13202,3,$1,$2,$3); }
	;

/*----------------------------------------------------------------------
 * Epsilon (optional) definitions.
 *----------------------------------------------------------------------*/

declaration_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| declaration_seq { $$ = prepend_prodrule($1,13302) ; }
	;

nested_name_specifier_opt:
	/* epsilon */ { $$ = NULL ; }
	| nested_name_specifier { $$ = prepend_prodrule($1,13402) ; }
	;

expression_list_opt:
	/* epsilon */ { $$ = NULL ; }
	| expression_list { $$ = prepend_prodrule($1,13502) ; }
	;

COLONCOLON_opt:
	/* epsilon */ { $$ = NULL ; }
	| COLONCOLON { $$ = prepend_prodrule($1,13602) ; }
	;

new_placement_opt:
	/* epsilon */ { $$ = NULL ; }
	| new_placement { $$ = prepend_prodrule($1,13702) ; }
	;

new_initializer_opt:
	/* epsilon */ { $$ = NULL ; }
	| new_initializer { $$ = prepend_prodrule($1,13802) ; }
	;

new_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| new_declarator { $$ = prepend_prodrule($1,13902) ; }
	;

expression_opt:
	/* epsilon */ { $$ = NULL ; }
	| expression { $$ = prepend_prodrule($1,14002) ; }
	;

statement_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| statement_seq { $$ = prepend_prodrule($1,14102) ; }
	;

condition_opt:
	/* epsilon */ { $$ = NULL ; }
	| condition { $$ = prepend_prodrule($1,14202) ; }
	;

enumerator_list_opt:
	/* epsilon */ { $$ = NULL ; }
	| enumerator_list { $$ = prepend_prodrule($1,14302) ; }
	;

initializer_opt:
	/* epsilon */ { $$ = NULL ; }
	| initializer { $$ = prepend_prodrule($1,14402) ; }
	;

constant_expression_opt:
	/* epsilon */ { $$ = NULL ; }
	| constant_expression { $$ = prepend_prodrule($1,14502) ; }
	;

abstract_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| abstract_declarator { $$ = prepend_prodrule($1,14602) ; }
	;

type_specifier_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| type_specifier_seq { $$ = prepend_prodrule($1,14702) ; }
	;

direct_abstract_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| direct_abstract_declarator { $$ = prepend_prodrule($1,14802) ; }
	;

ctor_initializer_opt:
	/* epsilon */ { $$ = NULL ; } // trouble maker
	| ctor_initializer { $$ = prepend_prodrule($1,14902) ; }
	;

COMMA_opt:
	/* epsilon */ { $$ = NULL ; }
	| ',' { $$ = prepend_prodrule($1,15002) ; }
	;

member_specification_opt:
	/* epsilon */ { $$ = NULL ; }
	| member_specification { $$ = prepend_prodrule($1,15102) ; }
	;

SEMICOLON_opt:
	/* epsilon */ { $$ = NULL ; }
	| ';' { $$ = prepend_prodrule($1,15202) ; }
	;

conversion_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| conversion_declarator { $$ = prepend_prodrule($1,15302) ; }
	;

EXPORT_opt:
	/* epsilon */ { $$ = NULL ; }
	| EXPORT { $$ = prepend_prodrule($1,15402) ; }
	;

handler_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| handler_seq { $$ = prepend_prodrule($1,15502) ; }
	;

assignment_expression_opt:
	/* epsilon */ { $$ = NULL ; }
	| assignment_expression { $$ = prepend_prodrule($1,15602) ; }
	;

type_id_list_opt:
	/* epsilon */ { $$ = NULL ; }
	| type_id_list { $$ = prepend_prodrule($1,15702) ; }
	;

%%

static void
yyerror(char *s)
{
    fprintf(stderr, "%s:%d: %s before '%s' token\n",
        yytoken.filename, yytoken.lineno, s, yytoken.text);
}

