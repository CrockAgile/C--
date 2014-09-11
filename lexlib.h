#ifndef lexlib
#define lexlib

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

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

// filestack interface
int push_file(int lineno);
int pop_file();
int delete_filestack();
void print_filestack();

// yytoken business
int update_yytoken(int, void*);
int string_update_yytoken(int, void*, char*);


// helper functions
void escape_char(char* src, char* dest);

#endif
