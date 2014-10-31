/* semantics.h
 * jeff crocker
 */
#ifndef SEMANTICS_H
#define	SEMANTICS_H
#define S_SIZE 1024
#define ENV_KIDS 8

#include <stdbool.h>
#include "lex.h"

typedef enum SemanticNode {
    // nodes that require new environment
    class_specifier = 950,
    compound_statement = 510,
    selection_statement = 530,
    iteration_statement = 550,
    function_definition = 900,

    // nodes that require adding to environment
    // function_definiton previously defined
    // class_specifier also previously defined
    init_declarator = 770,
    parameter_declarator = 890,
} SemanticNode;

void* sem_malloc(int size, bool zero);

typedef enum btype{
        int_type,
        bool_type,
        void_type,
        char_type,
        double_type,
        class_type,
        // complicated linked types
        pointer_type,
        function_type,
        array_type,
} btype;

// type element
typedef struct type_el {
    btype type; // basic types
    struct type_el *sub; // sub-lvls
    struct type_el *next;
} type_el;

struct environ;

typedef struct table_el {
    // needed by Vars, Funcs, and Classes
    token *tok;
    type_el *type;
    bool cons, defd;
    // needed by Funcs, and Classes
    type_el *param_types;
    struct environ *par_env;
    struct environ *chl_env;
    struct table_el *next;
} table_el;

typedef struct environ {
    table_el **locals; // vars, funcs, classes
    struct environ *up; // parent
    // only way I could figure to implement block definitions
    // I know they aren't required but seemed fake w/o them
    short nkids, ksize;
    struct environ **kids; 
} environ;

// for a stack of environ references
typedef struct env_el {
    environ *env;
    struct env_el *next;
} env_el;

type_el* mk_type_el(btype t, type_el *s, type_el *n);
void free_type_list(type_el* head);
table_el* mk_table_el(token *t, type_el *ty, environ *p, table_el *n);
void free_table_list(table_el *head);
environ* mk_environ(environ* parent);
void free_environ(environ *target);
unsigned long env_hash(char *s);

static environ* GlobalEnviron;
environ* GetGlobal();
static environ* curr_env;
environ* CurrEnv();
static env_el* env_stack;
void PushCurrEnv();
environ* PopEnv();
#endif	
