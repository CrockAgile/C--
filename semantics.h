/* semantics.h
 * jeff crocker
 */
#ifndef SEMANTICS_H
#define	SEMANTICS_H
#define S_SIZE 1024
#define ENV_KIDS 8

#include <stdbool.h>
#include "parse.h"
extern int include_success;
extern int iostream_included;
extern int sem_cleanup;

void* sem_malloc(int size, bool zero);

struct env;

typedef struct table_el {
    // needed by Vars, Funcs, and Classes
    token *tok;
    type_el *type;
    bool cons, defd;
    // needed by Funcs, and Classes
    type_el *param_types;
    struct env *par_env, *ch_env;
    struct table_el *next;
} table_el;

typedef struct env {
    table_el **locals; // vars, funcs, classes
    struct env *up; // parent
    // only way I could figure to implement block definitions
    // I know they aren't required but seemed fake w/o them
    short nkids, ksize, depth;
    struct env **kids;
    char *name;
} env;

// for a stack of environ references

typedef struct env_el {
    env *env;
    struct env_el *next;
} env_el;

unsigned long env_hash(char *s);
type_el* mk_type_el(btype t, type_el *s, type_el *n);
void free_type_list(type_el* head);
void print_type(type_el*, type_el*);
void print_type_list(type_el *head, type_el *p);
table_el* mk_table_el(token *t, type_el *ty, env *p, table_el *n);
void free_table_list(table_el *head);
env* mk_environ(env* parent, char *s, int depth);
table_el* environ_lookup(env *e, char *key);
table_el* environ_insert(env *e, token *to, type_el *ty, type_el *pl, bool c, bool d);
env* add_env_child(env *parent, char*n);
void free_environ(env *target);

env* GlobalEnviron;
env* GetGlobal();
env* curr_env;
env* CurrEnv();
env_el* env_stack;
void print_environ(env *t);
void PushCurrEnv();
env* LinkCurrEnv(token *t);
env* PopEnv();

/* TREE TRAVERSALS SECTION */

typedef enum SemanticNode {
    // nodes that require only new environment
    selection_statement = 530,
    iteration_statement = 550,
    compound_statement = 510,
    // nodes that require adding to table
    start_state = 140,
    init_declarator = 770,
    simple_declaration = 620,
    parameter_declarator = 890,
    param_decl_clause = 870,
    member_declaration = 990,
    // nodes that require both new env, and adding
    class_specifier = 950,
    class_name = 40,
    function_definition = 900,

} SemanticNode;

typedef enum ExprNode {
    mul_expr = 3302,
    div_expr = 3303,
    mod_expr = 3304,
    literal = 1501,
    identifier = 701,
    add_expr = 3402,
    sub_expr = 3403,
    SL_expr = 3502,
    SR_expr = 3503,
    LT_expr = 3602,
    GT_expr = 3603,
    LE_expr = 3604,
    GE_expr = 3605,
    EE_expr = 3702,
    NE_expr = 3703,
    OR_expr = 4202,
    AND_expr = 4102,
    NOT_expr = 2203,
    par_expr = 1503,
    index_expr = 2002,
    point_expr = 2204,
    dot_expr = 2007,
    arrow_expr = 2011,
    inc_expr = 2012,
    asn_expr = 4402,
    init_decl = 7701,
} ExprNode;

table_el* func_loc;
void pre_semantics(struct prodrule*, struct pnode*);
void post_semantics(struct prodrule*, struct pnode*);
void semantic_traversal(struct pnode*);

void pre_decl_list(btype, struct pnode *i);
void pre_init_declarator(btype, struct pnode*);
type_el* pre_declarator(struct pnode*, btype, token**);
bool pre_optional_init(struct pnode*);
void param_decls(struct pnode*, type_el** h);
type_el* param_decl(struct prodrule*, struct pnode*);

bool type_comp(type_el *, type_el *);
bool table_type_comp(table_el*, table_el*);
struct pnode *UpFind(struct pnode *c, int code);
void pre_proto(struct pnode *r);
void proto_type(struct pnode *r, type_el **head);
type_el *indiv_protos(struct prodrule *pr, struct pnode *n);
struct pnode *DownFind(struct pnode *c, int code);
void type_check(struct prodrule *p, struct pnode *n);
void multi_type(struct pnode *n);
void assign_lit_type(struct prodrule *p, struct pnode *n);
#endif
