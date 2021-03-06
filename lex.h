#ifndef lexlib
#define lexlib

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "120gram.tab.h"

typedef struct name_insert {
    char *name;
    int code;
    struct name_insert *next;
} name_insert;

name_insert *qhead, *qtail;

void type_insert(char*, int);

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

token* mktoken(int, char*, int, char*, void*);

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

// linked list business
int add_to_tail(token* yy_token);
void print_token(token *t);
void print_tokenlist(token_el* start);

// helper functions
void escape_char(char* src, char* dest);

#endif
