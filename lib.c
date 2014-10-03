#include "lib.h"

extern token yytoken;
extern int yylineno;
extern char* yytext;
extern YYSTYPE yylval;
extern YYSTYPE root;

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



int add_to_tail(token* curr_yytoken) {
    token* yytoken_copy = (token*)malloc(sizeof(token));
    if(!yytoken_copy)
        return 0;

    yytoken_copy->code = curr_yytoken->code;
    yytoken_copy->text = curr_yytoken->text;
    yytoken_copy->lineno = curr_yytoken->lineno;
    yytoken_copy->filename = curr_yytoken->filename;
    yytoken_copy->lval = curr_yytoken->lval;

    token_el* added = (token_el*)malloc(sizeof(token_el));
    if(!added)
        return 0;

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
	printf("%-10s%-30s%-10s%-20s%-30s",
		"Category",
		"Text",
		"Lineno",
		"Filename",
		"Lval");
	int i;
	printf("\n");
	for (i = 0; i < 9; i++) {
		printf("----------");
	}
	printf("\n");
    while(start) {
        printf("%-10d%-30s%-10d%-20s",
            start->t->code,
            start->t->text,
            start->t->lineno,
            start->t->filename
        );
        switch(start->t->code){
            case INTEGER:
                printf("%-30d",*(int*)(start->t->lval));
                break;
            case FLOATING:
                printf("%-30f",*(float*)(start->t->lval));
                break;
            case STRING:
            case CHARACTER:
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

    //free(yytoken.text);
    yytoken.text = strdup(yytext);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    yylval = create_pnode(&yytoken);

    return code;
}

int lval_update_yytoken(int code, void* lval, char* orig) {

    yytoken.text = strdup(orig);
    yytoken.code = code;
    yytoken.lineno = yylineno;
    yytoken.lval = lval;

    yylval = create_pnode(&yytoken);

    return code;
}

int hash_name_el(struct name_el a) {
}

int nametable_insert(struct name_el *data, struct nametable *hash_table) {
    int i, hash;
    if(hash_table->num >= hash_table->size) {
        return 0; // TODO dynamic hash table size
    }

}

struct pnode *alcnode(int rule, int kids, ...) {
    va_list args;

    struct pnode* new_pnode = (struct pnode*)malloc(sizeof(struct pnode));
    if(!new_pnode)
        return NULL;

    new_pnode->prodrule = rule;
    new_pnode->nkids = kids;

    new_pnode->kids = (struct pnode**)malloc(kids * sizeof(struct pnode*));
    int x;
    va_start( args, kids );
    for ( x = 0; x < kids; x++ ) {
        new_pnode->kids[x] = va_arg(args,struct pnode*);
    }
    va_end( args );

    new_pnode->t = NULL;
    root = new_pnode;
    return new_pnode;
}

struct pnode* create_pnode(token* curr_yytoken) {
    token* yytoken_copy = (token*)malloc(sizeof(token));
    if(!yytoken_copy)
        return 0;

    yytoken_copy->code = curr_yytoken->code;
    yytoken_copy->text = curr_yytoken->text;
    yytoken_copy->lineno = curr_yytoken->lineno;
    yytoken_copy->filename = curr_yytoken->filename;
    yytoken_copy->lval = curr_yytoken->lval;

    struct pnode *new_pnode = (struct pnode*)malloc(sizeof(struct pnode));

    if(!new_pnode)
        return 0;

    new_pnode->prodrule = 0;
    new_pnode->nkids = 0;
    new_pnode->kids = NULL;
    new_pnode->t = yytoken_copy;

    return new_pnode;
}

int treeprint(struct pnode *p, int depth) {
    if (p == NULL) {
        printf("%*s Epsilon Expression\n", depth*2, " ");
        return 0;
    }
    int i;

    if (p->t) {
        printf("%*s !!%d!!\n", depth*2, " ", p->t->code);
    }
    else {
        printf("%*s %d: %d\n", depth*2, " ", p->prodrule, p->nkids);
    }
    for (i = 0; i < p->nkids; i++)
        treeprint(p->kids[i], depth+1);
}
