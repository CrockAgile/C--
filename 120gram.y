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
#include "lib.h"

extern token yytoken;
YYSTYPE root = NULL;
//int yydebug = 1;

static void yyerror(char *s);
%}

%expect 84

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
	TYPEDEF_NAME { $$ = $1 ; }
	;

namespace_name:
	original_namespace_name { $$ = $1 ; }
	;

original_namespace_name:
	/* identifier */
	NAMESPACE_NAME { $$ = $1 ; }
	;

class_name:
	/* identifier */
	CLASS_NAME { $$ = $1 ; }
	| template_id { $$ = $1 ; }
	;

enum_name:
	/* identifier */
	ENUM_NAME { $$ = $1 ; }
	;

template_name:
	/* identifier */
	TEMPLATE_NAME { $$ = $1 ; }
	;

/*----------------------------------------------------------------------
 * Lexical elements.
 *----------------------------------------------------------------------*/

identifier:
	IDENTIFIER { $$ = $1 ; }
	;

literal:
	integer_literal { $$ = $1 ; }
	| character_literal { $$ = $1 ; }
	| floating_literal { $$ = $1 ; }
	| string_literal { $$ = $1 ; }
	| boolean_literal { $$ = $1 ; }
	;

integer_literal:
	INTEGER { $$ = $1 ; }
	;

character_literal:
	CHARACTER { $$ = $1 ; }
	;

floating_literal:
	FLOATING { $$ = $1 ; }
	;

string_literal:
	STRING { $$ = $1 ; }
	;

boolean_literal:
	TRUE { $$ = $1 ; }
	| FALSE { $$ = $1 ; }
	;

/*----------------------------------------------------------------------
 * Translation unit.
 *----------------------------------------------------------------------*/

translation_unit:
	declaration_seq_opt { $$ = $1 ; root = $$; }
	;

/*----------------------------------------------------------------------
 * Expressions.
 *----------------------------------------------------------------------*/

primary_expression:
	literal { $$ = $1 ; }
	| THIS { $$ = $1 ; }
	| '(' expression ')' { $$ = alcnode(1503,3,$1,$2,$3); }
	| id_expression { $$ = $1 ; }
	;

id_expression:
	unqualified_id { $$ = $1 ; }
	| qualified_id { $$ = $1 ; }
	;

unqualified_id:
	identifier { $$ = $1 ; }
	| operator_function_id { $$ = $1 ; }
	| conversion_function_id { $$ = $1 ; }
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
	primary_expression { $$ = $1 ; }
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
	assignment_expression { $$ = $1 ; }
	| expression_list ',' assignment_expression { $$ = alcnode(2102,3,$1,$2,$3); }
	;

unary_expression:
	postfix_expression { $$ = $1 ; }
	| PLUSPLUS cast_expression { $$ = alcnode(2202,2,$1,$2); }
	| MINUSMINUS cast_expression { $$ = alcnode(2203,2,$1,$2); }
	| '*' cast_expression { $$ = alcnode(2204,2,$1,$2); }
	| '&' cast_expression { $$ = alcnode(2205,2,$1,$2); }
	| unary_operator cast_expression { $$ = alcnode(2206,2,$1,$2); }
	| SIZEOF unary_expression { $$ = alcnode(2207,2,$1,$2); }
	| SIZEOF '(' type_id ')' { $$ = alcnode(2208,4,$1,$2,$3,$4); }
	| new_expression { $$ = $1 ; }
	| delete_expression { $$ = $1 ; }
	;

unary_operator:
	  '+' { $$ = $1 ; }
	| '-' { $$ = $1 ; }
	| '!' { $$ = $1 ; }
	| '~' { $$ = $1 ; }
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
	| direct_new_declarator { $$ = $1 ; }
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
	unary_expression { $$ = $1 ; }
	| '(' type_id ')' cast_expression { $$ = alcnode(3102,4,$1,$2,$3,$4); }
	;

pm_expression:
	cast_expression { $$ = $1 ; }
	| pm_expression DOTSTAR cast_expression { $$ = alcnode(3202,3,$1,$2,$3); }
	| pm_expression ARROWSTAR cast_expression { $$ = alcnode(3203,3,$1,$2,$3); }
	;

multiplicative_expression:
	pm_expression { $$ = $1 ; }
	| multiplicative_expression '*' pm_expression { $$ = alcnode(3302,3,$1,$2,$3); }
	| multiplicative_expression '/' pm_expression { $$ = alcnode(3303,3,$1,$2,$3); }
	| multiplicative_expression '%' pm_expression { $$ = alcnode(3304,3,$1,$2,$3); }
	;

additive_expression:
	multiplicative_expression { $$ = $1 ; }
	| additive_expression '+' multiplicative_expression { $$ = alcnode(3402,3,$1,$2,$3); }
	| additive_expression '-' multiplicative_expression { $$ = alcnode(3403,3,$1,$2,$3); }
	;

shift_expression:
	additive_expression { $$ = $1 ; }
	| shift_expression SL additive_expression { $$ = alcnode(3502,3,$1,$2,$3); }
	| shift_expression SR additive_expression { $$ = alcnode(3503,3,$1,$2,$3); }
	;

relational_expression:
	shift_expression { $$ = $1 ; }
	| relational_expression '<' shift_expression { $$ = alcnode(3602,3,$1,$2,$3); }
	| relational_expression '>' shift_expression { $$ = alcnode(3603,3,$1,$2,$3); }
	| relational_expression LTEQ shift_expression { $$ = alcnode(3604,3,$1,$2,$3); }
	| relational_expression GTEQ shift_expression { $$ = alcnode(3605,3,$1,$2,$3); }
	;

equality_expression:
	relational_expression { $$ = $1 ; }
	| equality_expression EQ relational_expression { $$ = alcnode(3702,3,$1,$2,$3); }
	| equality_expression NOTEQ relational_expression { $$ = alcnode(3703,3,$1,$2,$3); }
	;

and_expression:
	equality_expression { $$ = $1 ; }
	| and_expression '&' equality_expression { $$ = alcnode(3802,3,$1,$2,$3); }
	;

exclusive_or_expression:
	and_expression { $$ = $1 ; }
	| exclusive_or_expression '^' and_expression { $$ = alcnode(3902,3,$1,$2,$3); }
	;

inclusive_or_expression:
	exclusive_or_expression { $$ = $1 ; }
	| inclusive_or_expression '|' exclusive_or_expression { $$ = alcnode(4002,3,$1,$2,$3); }
	;

logical_and_expression:
	inclusive_or_expression { $$ = $1 ; }
	| logical_and_expression ANDAND inclusive_or_expression { $$ = alcnode(4102,3,$1,$2,$3); }
	;

logical_or_expression:
	logical_and_expression { $$ = $1 ; }
	| logical_or_expression OROR logical_and_expression { $$ = alcnode(4202,3,$1,$2,$3); }
	;

conditional_expression:
	logical_or_expression { $$ = $1 ; }
	| logical_or_expression  '?' expression ':' assignment_expression { $$ = alcnode(4302,5,$1,$2,$3,$4,$5); }
	;

assignment_expression:
	conditional_expression { $$ = $1 ; }
	| logical_or_expression assignment_operator assignment_expression { $$ = alcnode(4402,3,$1,$2,$3); }
	| throw_expression { $$ = $1 ; }
	;

assignment_operator:
	'=' { $$ = $1 ; }
	| MULEQ { $$ = $1 ; }
	| DIVEQ { $$ = $1 ; }
	| MODEQ { $$ = $1 ; }
	| ADDEQ { $$ = $1 ; }
	| SUBEQ { $$ = $1 ; }
	| SREQ { $$ = $1 ; }
	| SLEQ { $$ = $1 ; }
	| ANDEQ { $$ = $1 ; }
	| XOREQ { $$ = $1 ; }
	| OREQ { $$ = $1 ; }
	;

expression:
	assignment_expression { $$ = $1 ; }
	| expression ',' assignment_expression { $$ = alcnode(4602,3,$1,$2,$3); }
	;

constant_expression:
	conditional_expression { $$ = $1 ; }
	;

/*----------------------------------------------------------------------
 * Statements.
 *----------------------------------------------------------------------*/

statement:
	labeled_statement { $$ = $1 ; }
	| expression_statement { $$ = $1 ; }
	| compound_statement { $$ = $1 ; }
	| selection_statement { $$ = $1 ; }
	| iteration_statement { $$ = $1 ; }
	| jump_statement { $$ = $1 ; }
	| declaration_statement { $$ = $1 ; }
	| try_block { $$ = $1 ; }
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
	statement { $$ = $1 ; }
	| statement_seq statement { $$ = alcnode(5201,2,$1,$2); }
	;

selection_statement:
	IF '(' condition ')' statement { $$ = alcnode(5301,5,$1,$2,$3,$4,$5); }
	| IF '(' condition ')' statement ELSE statement { $$ = alcnode(5302,7,$1,$2,$3,$4,$5,$6,$7); }
	| SWITCH '(' condition ')' statement { $$ = alcnode(5303,5,$1,$2,$3,$4,$5); }
	;

condition:
	expression { $$ = $1 ; }
	| type_specifier_seq declarator '=' assignment_expression { $$ = alcnode(5402,4,$1,$2,$3,$4); }
	;

iteration_statement:
	WHILE '(' condition ')' statement { $$ = alcnode(5501,5,$1,$2,$3,$4,$5); }
	| DO statement WHILE '(' expression ')' ';' { $$ = alcnode(5502,6,$1,$2,$3,$4,$5,$6); }
	| FOR '(' for_init_statement condition_opt ';' expression_opt ')' statement { $$ = alcnode(5503,8,$1,$2,$3,$4,$5,$6,$7,$8); }
	;

for_init_statement:
	expression_statement { $$ = $1 ; }
	| simple_declaration { $$ = $1 ; }
	;

jump_statement:
	BREAK ';' { $$ = alcnode(5701,2,$1,$2); }
	| CONTINUE ';' { $$ = alcnode(5702,2,$1,$2); }
	| RETURN expression_opt ';' { $$ = alcnode(5703,3,$1,$2,$3); }
	| GOTO identifier ';' { $$ = alcnode(5704,3,$1,$2,$3); }
	;

declaration_statement:
	block_declaration { $$ = $1 ; }
	;

/*----------------------------------------------------------------------
 * Declarations.
 *----------------------------------------------------------------------*/

declaration_seq:
	declaration { $$ = $1 ; }
	| declaration_seq declaration { $$ = alcnode(5901,2,$1,$2); }
	;

declaration:
	block_declaration { $$ = $1 ; }
	| function_definition { $$ = $1 ; }
	| template_declaration { $$ = $1 ; }
	| explicit_instantiation { $$ = $1 ; }
	| explicit_specialization { $$ = $1 ; }
	| linkage_specification { $$ = $1 ; }
	| namespace_definition { $$ = $1 ; }
	;

block_declaration:
	simple_declaration { $$ = $1 ; }
	| asm_definition { $$ = $1 ; }
	| namespace_alias_definition { $$ = $1 ; }
	| using_declaration { $$ = $1 ; }
	| using_directive { $$ = $1 ; }
	;

simple_declaration:
	  decl_specifier_seq init_declarator_list ';' { $$ = alcnode(6201,3,$1,$2,$3); }
	|  decl_specifier_seq ';' { $$ = alcnode(6202,2,$1,$2); }
	;

decl_specifier:
	storage_class_specifier { $$ = $1 ; }
	| type_specifier { $$ = $1 ; }
	| function_specifier { $$ = $1 ; }
	| FRIEND { $$ = $1 ; }
	| TYPEDEF { $$ = $1 ; }
	;

decl_specifier_seq:
	  decl_specifier { $$ = $1 ; }
	| decl_specifier_seq decl_specifier { $$ = alcnode(6402,2,$1,$2); }
	;

storage_class_specifier:
	AUTO { $$ = $1 ; }
	| REGISTER { $$ = $1 ; }
	| STATIC { $$ = $1 ; }
	| EXTERN { $$ = $1 ; }
	| MUTABLE { $$ = $1 ; }
	;

function_specifier:
	INLINE { $$ = $1 ; }
	| VIRTUAL { $$ = $1 ; }
	| EXPLICIT { $$ = $1 ; }
	;

type_specifier:
	simple_type_specifier { $$ = $1 ; }
	| class_specifier { $$ = $1 ; }
	| enum_specifier { $$ = $1 ; }
	| elaborated_type_specifier { $$ = $1 ; }
	| cv_qualifier { $$ = $1 ; }
	;

simple_type_specifier:
	  type_name { $$ = $1 ; }
	| nested_name_specifier type_name { $$ = alcnode(6802,2,$1,$2); }
	| COLONCOLON nested_name_specifier_opt type_name { $$ = alcnode(6803,3,$1,$2,$3); }
	| CHAR { $$ = $1 ; }
	| WCHAR_T { $$ = $1 ; }
	| BOOL { $$ = $1 ; }
	| SHORT { $$ = $1 ; }
	| INT { $$ = $1 ; }
	| LONG { $$ = $1 ; }
	| SIGNED { $$ = $1 ; }
	| UNSIGNED { $$ = $1 ; }
	| FLOAT { $$ = $1 ; }
	| DOUBLE { $$ = $1 ; }
	| VOID { $$ = $1 ; }
	;

type_name:
	class_name { $$ = $1 ; }
	| enum_name { $$ = $1 ; }
	| typedef_name { $$ = $1 ; }
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
	identifier { $$ = $1 ; }
	;
*/

enum_specifier:
	ENUM identifier '{' enumerator_list_opt '}' { $$ = alcnode(7201,5,$1,$2,$3,$4,$5); }
	;

enumerator_list:
	enumerator_definition { $$ = $1 ; }
	| enumerator_list ',' enumerator_definition { $$ = alcnode(7301,3,$1,$2,$3); }
	;

enumerator_definition:
	enumerator { $$ = $1 ; }
	| enumerator '=' constant_expression { $$ = alcnode(7401,3,$1,$2,$3); }
	;

enumerator:
	identifier { $$ = $1 ; }
	;

/*
namespace_name:
	original_namespace_name { $$ = $1 ; }
	| namespace_alias { $$ = $1 ; }
	;

original_namespace_name:
	identifier { $$ = $1 ; }
	;
*/

namespace_definition:
	named_namespace_definition { $$ = $1 ; }
	| unnamed_namespace_definition { $$ = $1 ; }
	;

named_namespace_definition:
	original_namespace_definition { $$ = $1 ; }
	| extension_namespace_definition { $$ = $1 ; }
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
	declaration_seq_opt { $$ = $1 ; }
	;

/*
namespace_alias:
	identifier { $$ = $1 ; }
	;
*/

namespace_alias_definition:
	NAMESPACE identifier '=' qualified_namespace_specifier ';' { $$ = alcnode(101,5,$1,$2,$3,$4,$5); }
	;

qualified_namespace_specifier:
	  COLONCOLON nested_name_specifier namespace_name { $$ = alcnode(101,3,$1,$2,$3); }
	| COLONCOLON namespace_name { $$ = alcnode(101,2,$1,$2); }
	| nested_name_specifier namespace_name { $$ = alcnode(101,2,$1,$2); }
	| namespace_name { $$ = $1 ; }
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
	init_declarator { $$ = $1 ; }
	| init_declarator_list ',' init_declarator { $$ = alcnode(7601,3,$1,$2,$3); }
	;

init_declarator:
	declarator initializer_opt { $$ = alcnode(7701,2,$1,$2); }
	;

declarator:
	direct_declarator { $$ = $1 ; }
	| ptr_operator declarator { $$ = alcnode(7801,2,$1,$2); }
	;

direct_declarator:
	  declarator_id { $$ = $1 ; }
	| direct_declarator '('parameter_declaration_clause ')' cv_qualifier_seq exception_specification { $$ = alcnode(7901,6,$1,$2,$3,$4,$5,$6); }
	| direct_declarator '('parameter_declaration_clause ')' cv_qualifier_seq { $$ = alcnode(7902,5,$1,$2,$3,$4,$5); }
	| direct_declarator '('parameter_declaration_clause ')' exception_specification { $$ = alcnode(7903,5,$1,$2,$3,$4,$5); }
	| direct_declarator '('parameter_declaration_clause ')' { $$ = alcnode(7904,4,$1,$2,$3,$4); }
	| direct_declarator '[' constant_expression_opt ']' { $$ = alcnode(7905,4,$1,$2,$3,$4); }
	| '(' declarator ')' { $$ = alcnode(7906,3,$1,$2,$3); }
	;

ptr_operator:
	'*' { $$ = $1 ; }
	| '*' cv_qualifier_seq { $$ = alcnode(8001,2,$1,$2); }
	| '&' { $$ = $1 ; }
	| nested_name_specifier '*' { $$ = alcnode(8002,2,$1,$2); }
	| nested_name_specifier '*' cv_qualifier_seq { $$ = alcnode(8003,3,$1,$2,$3); }
	| COLONCOLON nested_name_specifier '*' { $$ = alcnode(8004,3,$1,$2,$3); }
	| COLONCOLON nested_name_specifier '*' cv_qualifier_seq { $$ = alcnode(8005,4,$1,$2,$3,$4); }
	;

cv_qualifier_seq:
	cv_qualifier { $$ = $1 ; }
	| cv_qualifier cv_qualifier_seq { $$ = alcnode(8101,2,$1,$2); }
	;

cv_qualifier:
	CONST { $$ = $1 ; }
	| VOLATILE { $$ = $1 ; }
	;

declarator_id:
	  id_expression { $$ = $1 ; }
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
	| direct_abstract_declarator { $$ = $1 ; }
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
	| parameter_declaration_list { $$ = $1 ; }
	| ELLIPSIS { $$ = $1 ; }
	| parameter_declaration_list ',' ELLIPSIS { $$ = alcnode(8704,3,$1,$2,$3); }
	| { $$ = NULL ; }
	;

parameter_declaration_list:
	parameter_declaration { $$ = $1 ; }
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
	compound_statement { $$ = $1 ; }
	;

initializer:
	'=' initializer_clause { $$ = alcnode(9201,2,$1,$2); }
	| '(' expression_list ')' { $$ = alcnode(9202,3,$1,$2,$3); }
	;

initializer_clause:
	assignment_expression { $$ = $1 ; }
	| '{' initializer_list COMMA_opt '}' { $$ = alcnode(9301,4,$1,$2,$3,$4); }
	| '{' '}' { $$ = alcnode(9301,2,$1,$2); }
	;

initializer_list:
	initializer_clause { $$ = $1 ; }
	| initializer_list ',' initializer_clause { $$ = alcnode(9401,3,$1,$2,$3); }
	;

/*----------------------------------------------------------------------
 * Classes.
 *----------------------------------------------------------------------*/

class_specifier:
	class_head '{' member_specification_opt '}' { $$ = alcnode(9501,4,$1,$2,$3,$4); }
	;

class_head:
	  class_key identifier { $$ = alcnode(9601,2,$1,$2); }
	| class_key identifier base_clause { $$ = alcnode(9602,3,$1,$2,$3); }
	| class_key nested_name_specifier identifier { $$ = alcnode(9603,3,$1,$2,$3); }
	| class_key nested_name_specifier identifier base_clause { $$ = alcnode(9604,4,$1,$2,$3,$4); }
	;

class_key:
	CLASS { $$ = $1 ;}
	| STRUCT { $$ = $1 ;}
	| UNION { $$ = $1 ; }
	;

member_specification:
	member_declaration member_specification_opt { $$ = alcnode(9801,2,$1,$2); }
	| access_specifier ':' member_specification_opt { $$ = alcnode(9802,3,$1,$2,$3); }
	;

member_declaration:
	  decl_specifier_seq member_declarator_list ';' { $$ = alcnode(9901,3,$1,$2,$3); }
	| decl_specifier_seq ';' { $$ = alcnode(9902,2,$1,$2); }
	| member_declarator_list ';' { $$ = alcnode(9903,2,$1,$2); }
	| ';' { $$ = $1 ; }
	| function_definition SEMICOLON_opt { $$ = alcnode(9905,2,$1,$2); }
	| qualified_id ';' { $$ = alcnode(9906,2,$1,$2); }
	| using_declaration { $$ = $1 ; }
	| template_declaration { $$ = $1 ; }
	;

member_declarator_list:
	member_declarator { $$ = $1 ; }
	| member_declarator_list ',' member_declarator { $$ = alcnode(10002,3,$1,$2,$3); }
	;

member_declarator:
	| declarator { $$ = $1 ; }
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
	base_specifier { $$ = $1 ; }
	| base_specifier_list ',' base_specifier { $$ = alcnode(10402,3,$1,$2,$3); }
	;

base_specifier:
	  COLONCOLON nested_name_specifier class_name { $$ = alcnode(10501,3,$1,$2,$3); }
	| COLONCOLON class_name { $$ = alcnode(10502,2,$1,$2); }
	| nested_name_specifier class_name { $$ = alcnode(10503,2,$1,$2); }
	| class_name { $$ = $1 ; }
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
	PRIVATE { $$ = $1 ; }
	| PROTECTED { $$ = $1 ; }
	| PUBLIC { $$ = $1 ; }
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
	mem_initializer { $$ = $1 ; }
	| mem_initializer ',' mem_initializer_list { $$ = alcnode(11102,3,$1,$2,$3); }
	;

mem_initializer:
	mem_initializer_id '(' expression_list_opt ')' { $$ = alcnode(11201,4,$1,$2,$3,$4); }
	;

mem_initializer_id:
	  COLONCOLON nested_name_specifier class_name { $$ = alcnode(11301,3,$1,$2,$3); }
	| COLONCOLON class_name { $$ = alcnode(11302,2,$1,$2); }
	| nested_name_specifier class_name { $$ = alcnode(11303,2,$1,$2); }
	| class_name { $$ = $1 ; }
	| identifier { $$ = $1 ; }
	;

/*----------------------------------------------------------------------
 * Overloading.
 *----------------------------------------------------------------------*/

operator_function_id:
	OPERATOR operator { $$ = alcnode(11401,2,$1,$2); }
	;

operator:
	NEW { $$ = $1 ; }
	| DELETE { $$ = $1 ; }
	| NEW '[' ']' { $$ = alcnode(11503,3,$1,$2,$3); }
	| DELETE '[' ']' { $$ = alcnode(11504,3,$1,$2,$3); }
	| '+' { $$ = $1 ; }
	| '_' { $$ = $1 ; }
	| '*' { $$ = $1 ; }
	| '/' { $$ = $1 ; }
	| '%' { $$ = $1 ; }
	| '^' { $$ = $1 ; }
	| '&' { $$ = $1 ; }
	| '|' { $$ = $1 ; }
	| '~' { $$ = $1 ; }
	| '!' { $$ = $1 ; }
	| '=' { $$ = $1 ; }
	| '<' { $$ = $1 ; }
	| '>' { $$ = $1 ; }
	| ADDEQ { $$ = $1 ; }
	| SUBEQ { $$ = $1 ; }
	| MULEQ { $$ = $1 ; }
	| DIVEQ { $$ = $1 ; }
	| MODEQ { $$ = $1 ; }
	| XOREQ { $$ = $1 ; }
	| ANDEQ { $$ = $1 ; }
	| OREQ { $$ = $1 ; }
	| SL { $$ = $1 ; }
	| SR { $$ = $1 ; }
	| SREQ { $$ = $1 ; }
	| SLEQ { $$ = $1 ; }
	| EQ { $$ = $1 ; }
	| NOTEQ { $$ = $1 ; }
	| LTEQ { $$ = $1 ; }
	| GTEQ { $$ = $1 ; }
	| ANDAND { $$ = $1 ; }
	| OROR { $$ = $1 ; }
	| PLUSPLUS { $$ = $1 ; }
	| MINUSMINUS { $$ = $1 ; }
	| ',' { $$ = $1 ; }
	| ARROWSTAR { $$ = $1 ; }
	| ARROW { $$ = $1 ; }
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
	template_parameter { $$ = $1 ; }
	| template_parameter_list ',' template_parameter { $$ = alcnode(11701,3,$1,$2,$3); }
	;

template_parameter:
	type_parameter { $$ = $1 ; }
	| parameter_declaration { $$ = $1 ; }
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
	template_argument { $$ = $1 ; }
	| template_argument_list ',' template_argument { $$ = alcnode(12102,3,$1,$2,$3); }
	;

template_argument:
	assignment_expression { $$ = $1 ; }
	| type_id { $$ = $1 ; }
	| template_name { $$ = $1 ; }
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
	| type_specifier_seq { $$ = $1 ; }
	| ELLIPSIS { $$ = $1 ; }
	;

throw_expression:
	THROW assignment_expression_opt { $$ = alcnode(13001,2,$1,$2); }
	;

exception_specification:
	THROW '(' type_id_list_opt ')' { $$ = alcnode(13101,4,$1,$2,$3,$4); }
	;

type_id_list:
	type_id { $$ = $1 ; }
	| type_id_list ',' type_id { $$ = alcnode(13201,3,$1,$2,$3); }
	;

/*----------------------------------------------------------------------
 * Epsilon (optional) definitions.
 *----------------------------------------------------------------------*/

declaration_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| declaration_seq { $$ = $1 ; }
	;

nested_name_specifier_opt:
	/* epsilon */ { $$ = NULL ; }
	| nested_name_specifier { $$ = $1 ; }
	;

expression_list_opt:
	/* epsilon */ { $$ = NULL ; }
	| expression_list { $$ = $1 ; }
	;

COLONCOLON_opt:
	/* epsilon */ { $$ = NULL ; }
	| COLONCOLON { $$ = $1 ; }
	;

new_placement_opt:
	/* epsilon */ { $$ = NULL ; }
	| new_placement { $$ = $1 ; }
	;

new_initializer_opt:
	/* epsilon */ { $$ = NULL ; }
	| new_initializer { $$ = $1 ; }
	;

new_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| new_declarator { $$ = $1 ; }
	;

expression_opt:
	/* epsilon */ { $$ = NULL ; }
	| expression { $$ = $1 ; }
	;

statement_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| statement_seq { $$ = $1 ; }
	;

condition_opt:
	/* epsilon */ { $$ = NULL ; }
	| condition { $$ = $1 ; }
	;

enumerator_list_opt:
	/* epsilon */ { $$ = NULL ; }
	| enumerator_list { $$ = $1 ; }
	;

initializer_opt:
	/* epsilon */ { $$ = NULL ; }
	| initializer { $$ = $1 ; }
	;

constant_expression_opt:
	/* epsilon */ { $$ = NULL ; }
	| constant_expression { $$ = $1 ; }
	;

abstract_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| abstract_declarator { $$ = $1 ; }
	;

type_specifier_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| type_specifier_seq { $$ = $1 ; }
	;

direct_abstract_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| direct_abstract_declarator { $$ = $1 ; }
	;

ctor_initializer_opt:
	/* epsilon */ { $$ = NULL ; } // trouble maker
	| ctor_initializer { $$ = $1 ; }
	;

COMMA_opt:
	/* epsilon */ { $$ = NULL ; }
	| ',' { $$ = $1 ; }
	;

member_specification_opt:
	/* epsilon */ { $$ = NULL ; }
	| member_specification { $$ = $1 ; }
	;

SEMICOLON_opt:
	/* epsilon */ { $$ = NULL ; }
	| ';' { $$ = $1 ; }
	;

conversion_declarator_opt:
	/* epsilon */ { $$ = NULL ; }
	| conversion_declarator { $$ = $1 ; }
	;

EXPORT_opt:
	/* epsilon */ { $$ = NULL ; }
	| EXPORT { $$ = $1 ; }
	;

handler_seq_opt:
	/* epsilon */ { $$ = NULL ; }
	| handler_seq { $$ = $1 ; }
	;

assignment_expression_opt:
	/* epsilon */ { $$ = NULL ; }
	| assignment_expression { $$ = $1 ; }
	;

type_id_list_opt:
	/* epsilon */ { $$ = NULL ; }
	| type_id_list { $$ = $1 ; }
	;

%%

static void
yyerror(char *s)
{
    fprintf(stderr, "%s:%d: %s before '%s' token\n",
        yytoken.filename, yytoken.lineno, s, yytoken.text);
}

