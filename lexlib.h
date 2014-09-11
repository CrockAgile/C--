#ifndef lexlib
#define lexlib

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

struct s_token {
    int category;
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
int push_file(char* filename, int lineno);
int pop_file(char* name_buff);
int delete_filestack();
void print_filestack();

// yytoken business
int update_yytoken(int, int, char*, void*);
int buffer_up_yytoken(int, char*, int, char*, void*);


// helper functions
void escape_char(char* src, char* dest);

#endif
