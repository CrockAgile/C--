#include "lex.h"

extern token yytoken;
extern int yylineno;
extern char* yytext;
extern YYSTYPE yylval;
extern YYSTYPE root;

token* mktoken(int c, char* t, int ln, char* fn, void* lval) {
    token *nt = calloc(1,sizeof (token));
    nt->code = c;
    nt->text = t;
    nt->lineno = ln;
    nt->filename = fn;
    nt->lval = lval;
    return nt;
}

// struct s_token {
//   int code;
//   char* text;
//   int lineno;
//   char* filename;
//   void* lval;
// };

void type_insert(char *name, int code) {
    name_insert *new = calloc(1,sizeof (name_insert));
    if (!new)
        exit(0);
    new->name = name;
    new->code = code;
    new->next = qhead;
    qhead = new;
}

int push_file(int lineno) {
    file_el* pushed = (file_el*) calloc(1,sizeof (file_el));
    if (!pushed)
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

int delete_filestack() {
    while (filestack_top) {
        file_el* next = filestack_top->next;
        free(filestack_top->filename);
        free(filestack_top);
        filestack_top = next;
    }
    return 1;
}

void print_filestack() {
    file_el* curr = filestack_top;
    printf("/***TOP***\n");
    while (curr != NULL) {
        printf("%s:%d\n", curr->filename, curr->curr_line);
        curr = curr->next;
    }
    printf("***BOT***/\n");
}

int add_to_tail(token* curr_yytoken) {
    token* yytoken_copy = (token*) calloc(1,sizeof (token));
    if (!yytoken_copy)
        return 0;

    yytoken_copy->code = curr_yytoken->code;
    yytoken_copy->text = curr_yytoken->text;
    yytoken_copy->lineno = curr_yytoken->lineno;
    yytoken_copy->filename = curr_yytoken->filename;
    yytoken_copy->lval = curr_yytoken->lval;

    token_el* added = (token_el*) calloc(1,sizeof (token_el));
    if (!added)
        return 0;

    added->t = yytoken_copy;
    added->next = NULL;

    if (tokenlist_tail) {
        tokenlist_tail->next = added;
    } else {
        tokenlist_head = added;
    }
    tokenlist_tail = added;
    return 1;
}

void print_token(token *t) {
    printf("%-10d%-30s%-10d%-20s",
            t->code,
            t->text,
            t->lineno,
            t->filename
            );
    switch (t->code) {
        case INTEGER:
            printf("%-30d", *(int*) (t->lval));
            break;
        case FLOATING:
            printf("%-30f", *(float*) (t->lval));
            break;
        case STRING:
        case CHARACTER:
            printf("%-30s", (char*) (t->lval));
            break;
    }
    putchar('\n');
}

void print_tokenlist(token_el* start) {
    printf("%-10s%-30s%-10s%-20s%-30s",
            "Category",
            "Text",
            "Lineno",
            "Filename",
            "Lval");
    int i;
    putchar('\n');
    for (i = 0; i < 9; i++) {
        printf("----------");
    }
    putchar('\n');
    while (start) {
        print_token(start->t);
        start = start->next;
    }
}

void escape_char(char* src, char* dest) {
    switch (src[1]) {
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
