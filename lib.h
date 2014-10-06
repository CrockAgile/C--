#ifndef lexlib
#define lexlib

#define SUFF_SIZE 100

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "120gram.tab.h"

struct s_token {
    int code;
    char* text;
    int lineno;
    char* filename;
    void* lval;
};

typedef struct s_token token;

struct token_elem {
    token* t;
    struct token_elem* next;
};

typedef struct token_elem token_el;

struct file_elem {
    char* filename;
    int curr_line;
    struct file_elem* next;
};

typedef struct file_elem file_el;

file_el* filestack_top;
token_el* tokenlist_head;
token_el* tokenlist_tail;

// filestack interface
int push_file(int lineno);
int pop_file();
int delete_filestack();
void print_filestack();

// yytoken business
int update_yytoken(int, void*);
int lval_update_yytoken(int, void*, char*);

// linked list business
int add_to_tail(token* yy_token);
void print_tokenlist(token_el* start);

// helper functions
void escape_char(char* src, char* dest);

struct name_el {
    char *name;
    int type;
    struct name_el *next;
};

struct nametable {
    int size;
    int num;
    struct name_el ** elements;
};

int hash_name_el(struct name_el a);
int nametable_insert(struct name_el*, struct nametable*);

#endif

#ifndef parselib
#define parselib

#include <stdarg.h>
#include <stdlib.h>

#define TABLESIZE 1000

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
void treeprint(struct pnode *p, int depth);

char* craft_readable(char* base, int prodrule);
void humanreadable(struct pnode* readme, char **dest);
struct pnode* prepend_prodrule(struct pnode* des, int code);

struct hash_el {
    token* t;
    int code;
    struct hash_el* next;
};

struct hash_el **nametable;

int init_nametable();
unsigned long hash_name(unsigned char*);
int insert_name(struct hash_el*);
struct hash_el* lookup_name(char*);

#endif
