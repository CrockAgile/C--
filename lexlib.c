#include "lexlib.h"

struct token {
    int category;
    char* text;
    int lineno;
    char* filename;
    int ival;
    int* sval;
};

typedef struct token token;

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

int push_file(char* newfile, int lineno) {
    file_el* pushed = (file_el*)malloc(sizeof(file_el));
    if(!pushed)
        return 0;

    pushed->filename = (char*)malloc(strlen(newfile)+1);
    if(!pushed->filename)
        return 0;

    strcpy(pushed->filename,newfile);
    pushed->curr_line = lineno;
    pushed->next = (file_el*)filestack_top;
    filestack_top = pushed;
    return 1;
}

int pop_file(char* name_buff) {
    file_el* popped = filestack_top;
    if(name_buff)
        strcpy(name_buff,popped->filename);

    free(popped->filename);

    filestack_top = popped->next;
    int resumed_line = popped->curr_line;
    free(popped);
    return resumed_line;
}

int delete_filestack(){
    while( filestack_top ){
        file_el* next = filestack_top->next;
        free(filestack_top->filename);
        free(filestack_top);
        filestack_top = next;
    }
}

void print_filestack() {
    file_el* curr = filestack_top;
    printf("/***TOP***\n");
    while( curr != NULL){
        printf("%s:%d\n",curr->filename,curr->curr_line);
        curr = curr->next;
    }
    printf("***BOT***/\n");
}
