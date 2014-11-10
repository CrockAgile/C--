/* semantics.h
 * jeff crocker
 */
#ifndef SEMANTICS_H
#define	SEMANTICS_H
#define S_SIZE 1024
#define ENV_KIDS 8

#include <stdbool.h>
#include "parse.h"

void* sem_malloc(int size, bool zero);

/* TYPES AND ENVIRONS SECTION */

typedef enum btype{
        int_type = 321,
        bool_type = 295,
        void_type = 352,
        char_type = 299,
        double_type = 307,
        class_type = 300,
        // complicated linked types
        pointer_type,
        function_type,
        array_type,
} btype;

// type element
typedef struct type_el {
    btype type; // basic types
    int elements;
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
    short childnum;
    struct table_el *next;
} table_el;

typedef struct environ {
    table_el **locals; // vars, funcs, classes
    struct environ *up; // parent
    // only way I could figure to implement block definitions
    // I know they aren't required but seemed fake w/o them
    short nkids, ksize, depth;
    struct environ **kids; 
} environ;

// for a stack of environ references
typedef struct env_el {
    environ *env;
    struct env_el *next;
} env_el;

unsigned long env_hash(char *s);
type_el* mk_type_el(btype t, type_el *s, type_el *n);
void free_type_list(type_el* head);
void print_type(type_el*);
void print_type_list(type_el *head);
table_el* mk_table_el(token *t, type_el *ty, environ *p, table_el *n);
void free_table_list(table_el *head);
environ* mk_environ(environ* parent,int depth);
table_el* environ_lookup(environ *e, char *key);
bool environ_insert(environ *e, token *to, type_el *ty, bool c, bool d);
environ* add_env_child(environ *parent);
void free_environ(environ *target);

environ* GlobalEnviron;
environ* GetGlobal();
environ* curr_env;
environ* CurrEnv();
env_el* env_stack;
void print_environ(environ *t);
void PushCurrEnv();
environ* PopEnv();

/* TREE TRAVERSALS SECTION */

typedef enum SemanticNode {
    // nodes that require only new environment
    selection_statement = 530,
    iteration_statement = 550,
    compound_statement = 510,
    // nodes that require adding to table
    init_declarator = 770,
    simple_declarator = 610,
    parameter_declarator = 890,
    // nodes that require both new env, and adding
    class_specifier = 950,
    function_definition = 900,

} SemanticNode;

void preorder_semantics(struct prodrule*, struct pnode*); 
void postorder_semantics(struct prodrule*, struct pnode*);
void semantic_traversal(struct pnode*);

void pre_init_list(btype,struct pnode *i);
void pre_init_declarator(btype, struct pnode*);
type_el* pre_declarator(struct pnode*,token**);
bool pre_optional_init(struct pnode*);
#endif	
