#include "lexlib.h"

extern token yytoken;
extern int yylineno;
extern char* yytext;

int push_file(int lineno) {
    file_el* pushed = (file_el*)malloc(sizeof(file_el));
    if(!pushed)
        return 0;

    pushed->filename = yytoken.filename;

    pushed->curr_line = lineno;
    pushed->next = filestack_top;
    filestack_top = pushed;
    return 1;
}

int pop_file() {
    file_el* popped = filestack_top;
    yytoken.filename = popped->filename;

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

int update_yytoken(int code, void* lval) {
    if(yytoken.lval)
        free(yytoken.lval);
    if(yytoken.text)
        free(yytoken.text);

    yytoken.text = strdup(yytext);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    return code;
}

int string_update_yytoken(int code, void* lval, char* orig) {
    if(yytoken.lval)
        free(yytoken.lval);
    if(yytoken.text)
        free(yytoken.text);

    yytoken.text = strdup(orig);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    return code;
}
