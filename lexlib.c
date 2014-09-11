#include "lexlib.h"

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

void escape_char(char* src, char* dest) {
    switch(src[1]){
        case 'a':
            *dest = '\a';
            break;
        case 'b':
            *dest = '\b';
            break;
        case 't':
            *dest = '\t';
            break;
        case 'n':
            *dest = '\n';
            break;
        case 'v':
            *dest = '\v';
            break;
        case 'f':
            *dest = '\f';
            break;
        case 'r':
            *dest = '\r';
            break;
        case '\\':
            *dest = '\\';
            break;
        case '\'':
            *dest = '\'';
            break;
        case '\"':
            *dest = '\"';
            break;
    }
}
