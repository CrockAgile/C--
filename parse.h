#ifndef parselib
#define parselib

#include <stdarg.h>
#include <stdlib.h>
#include "lex.h"

#define TABLESIZE 1000
#define SUFF_SIZE 100

// yytoken business
int update_yytoken(int, void*);
int lval_update_yytoken(int, void*, char*);

// linked list of prodrules to save info
// otherwise lost in $$ = $1
struct prodrule {
    int code;
    struct prodrule *next;
};

struct pnode {
    struct prodrule *prule;
    int nkids;
    struct pnode **kids;
    token *t;
};

struct pnode *alcnode(int rule, int kids, ...);
struct pnode* create_pnode(token* curr_yytoken);

// prints tree in depth format with
// abridged production rule history
void treeprint(struct pnode *p, int depth);
void freetree(struct pnode *p);

// appends correct numbering for human readable format
char* craft_readable(char* base, int prodrule);
// gigantic switch statement that derives human readable format
// based on production code.
void humanreadable(struct prodrule* , char **dest);
struct pnode* prepend_prodrule(struct pnode* des, int code);

// global for hashtable of names
token_el **nametable;
int init_nametable();
void free_nametable();
unsigned long hash_name(char*);
int insert_name( token*,int);
token_el* lookup_name(char*);
int id_check(char*,int);

#endif
