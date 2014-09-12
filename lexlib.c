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

int code;
char* text;
int lineno;
char* filename;
void* lval;

int add_to_tail(token* curr_yytoken) {
    token* yytoken_copy = (token*)malloc(sizeof(token));
    yytoken_copy->code = curr_yytoken->code;
    yytoken_copy->text = curr_yytoken->text;
    yytoken_copy->lineno = curr_yytoken->lineno;
    yytoken_copy->filename = curr_yytoken->filename;
    yytoken_copy->lval = curr_yytoken->lval;

    token_el* added = (token_el*)malloc(sizeof(token_el));
    added->t = yytoken_copy;
    added->next = NULL;

    if(tokenlist_tail){
        tokenlist_tail->next = added;
    }
    else{
        tokenlist_head = added;
    }
    tokenlist_tail = added;
}
void print_tokenlist(token_el* start) {
    while(start) {
        printf("%-30d%-20s%-30d%-30s",
            start->t->code,
            start->t->text,
            start->t->lineno,
            start->t->filename
        );
        switch(start->t->code){
            case ICON:
                printf("%-30d",*(int*)(start->t->lval));
                break;
            case FCON:
                printf("%-30f",*(float*)(start->t->lval));
                break;
            case STRING:
            case CCON:
                printf("%-30s",(char*)(start->t->lval));
                break;
        }
        printf("\n");
        start = start->next;
    }
}

void escape_char(char* src, char* dest) {
    switch(src[1]){
        case '0':
            *dest = '\0';
            break;
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

    yytoken.text = strdup(yytext);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    return code;
}

int lval_update_yytoken(int code, void* lval, char* orig) {

    yytoken.text = strdup(orig);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    return code;
}