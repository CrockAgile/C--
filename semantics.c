/* semantics.c
 * jeff crocker
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "semantics.h"

void* sem_malloc(int size, bool zero) {
    void* new;
    zero ? (new = calloc(1,size)) : (new = malloc(size));
    if (!new){
        fprintf(stderr,"Memory allocation failed in Semantic Analysis\n");
        exit(3);
    }
    return new;
}

/* TYPES AND ENVIRONS SECTION */

// hash with mod specific to semantic tables
unsigned long env_hash(char *s) {
    unsigned long hash = 5381;
    int c;
    while( (c = *s++) )
        hash = ((hash << 5) + hash) + c;
    return hash % S_SIZE;
}


type_el* mk_type_el(btype t, type_el *s, type_el *n) {
    type_el *new = sem_malloc(sizeof(type_el),0);// -1 indicates elems N/A
    new->type = t; new->sub = s; new->next = n; new->elements = -1;
    return new;
}

// lisp flashbacks
void free_type_list(type_el* head) {
    if (!head) return;
    type_el *prev, *curr = head;
    type_el *subp, *subc = head->sub;
    while( (prev = curr) ) {
        curr = curr->next;
        while( (subp = subc) ) {
            subc = subc->next;
            free(subp);
        }
        free(prev);
    }
}

void print_type(type_el *curr) {
    switch( curr->type ) {
        case class_type:
            printf("class");
            break;
        case pointer_type:
            printf("*");
            break;
        case function_type:
            printf("func");
            break;
        case array_type:
            printf("[]");
            break;
        case int_type:
            printf("int");
            break;
        default:
            printf(" default %d",curr->type);
    }
}

void print_type_list(type_el *head) {
    type_el* sub;
    while( head ) {
       print_type(head);
       sub = head->sub; 
       while( sub ) {
           print_type(sub);
           sub = sub->next;
       }
       head = head->next;
    }
}

table_el* mk_table_el(token *t, type_el *ty, environ *p, table_el *n) {
    table_el *new = sem_malloc(sizeof(table_el),1);
    new->tok = t; new->type = ty; new->par_env = p; new->next = n;
    // other elements zeroed from calloc
    return new;
}

void free_table_list(table_el *head) {
    table_el *prev, *curr = head;
    while ( (prev = curr) ) {
        curr = curr->next;
        // tokens are freed in parse cleanup
        free_type_list(prev->type);
        free_type_list(prev->param_types);
        free(prev);
    }
}

environ* mk_environ(environ *parent, int depth) {
    environ *new = sem_malloc(sizeof(environ),1);
    new->locals = sem_malloc(S_SIZE * sizeof(table_el*),1);
    new->up = parent;
    new->ksize = ENV_KIDS;
    new->depth = depth;
    new->kids = sem_malloc(ENV_KIDS * sizeof(environ*),1);
    return new;
}

table_el* environ_lookup(environ *e, char *key) {
    table_el* res = e->locals[env_hash(key)];
    if (res) {
        while (res) {
            if (!strcmp(key,res->tok->text)) {
                return res;
            }
            res = res->next;
        }
    }
    return NULL;
}

bool environ_insert(environ *e, token *to, type_el *ty, bool c, bool d) {
    unsigned long index = env_hash(to->text);
    table_el** des = &(e->locals[index]);
    // if already in table, error
    if (environ_lookup(e,to->text)) {
        fprintf(stderr,"Double declaration of %s\n",to->text);
        exit(3);
    }
    // make new table element
    table_el* new = sem_malloc(sizeof(table_el),1);
    new->tok = to;
    new->type = ty;
    new->cons = c; new->defd = d;
    // prepend to list of hash collisions
    new->next = *des;
    *des = new;
    return 1;
}

environ* add_env_child(environ *parent) {
    short nkids = parent->nkids;
    environ *new;
    if (!parent) return NULL;

    if ( nkids == parent->ksize ) {// at max capacity
        parent->kids = realloc(parent->kids,nkids*2 *sizeof(environ*));
        if (!parent->kids) exit(3);
        parent->ksize = 2*nkids; // update with new sizes
    }
    new = mk_environ(parent,parent->depth+1);
    parent->kids[parent->nkids++] = new;
    return new;
}

void free_environ(environ *target) {
    if (!target) return;
    int i;
    short nkids;
    environ *child;
    table_el *l;
    for (i=0; i<S_SIZE; i++){
        l = target->locals[i];
        if (l) free_table_list(l);
    }
    // dont free parent, handled in tree traversal
    nkids = target->nkids; // save for future compares
    for (i=0; i<=nkids; i++) {
        child = target->kids[i];
        if (child) {
            free_environ(child);
        }
    }
    // now that all occupied indexes freed
    free(target->kids);
    free(target->locals);
    free(target);
}

environ* GetGlobal() {
    if (!GlobalEnviron) // singleton?
        GlobalEnviron = mk_environ(NULL,0);
    // 'GLOBAL' environ is special case environ
    // that has no parent and depth 0, i.e. root
    return GlobalEnviron;
}

environ* CurrEnv() {
    if (!curr_env)
        curr_env = GetGlobal();
    return curr_env;
}

void print_environ(environ *curr) {
    if (!curr) return;
    int i, nkids;
    table_el *res;
    printf("%*s%d: ",curr->depth*2, " ",curr->depth);
    for (i=0; i<S_SIZE; i++) {
        res = curr->locals[i];
        if (res) {
            printf(" %d,%s,", i, res->tok->text);
            print_type_list(res->type);
        }
    }
    printf("\n");
    nkids = curr->nkids;
    for (i=0;i<=nkids;i++)
        print_environ(curr->kids[i]);
}

void PushCurrEnv() {
    env_el *new = sem_malloc(sizeof(env_el),0);
    environ *old_curr = CurrEnv();
    new->env = old_curr;
    new->next = env_stack;
    env_stack = new;

    curr_env = add_env_child(old_curr);
}

environ* PopEnv() {
    env_el* del = env_stack;
    env_stack = env_stack->next;
    environ *res = del->env;
    free(del);

    curr_env = res;
    return res;
}

/* TREE TRAVERSALS SECTION */

void preorder_semantics(struct prodrule *p, struct pnode* n){
    btype bt;
    switch(p->code / 10) {
        case compound_statement:
            PushCurrEnv();
            break;
        case simple_declaration:
            bt = n->kids[0]->t->code;
            pre_init_list(bt,n->kids[1]);
            break;
    }
}

void postorder_semantics(struct prodrule *p, struct pnode* n){
    switch(p->code / 10) {
        case compound_statement:
            PopEnv();
            break;
    }
}

void semantic_traversal(struct pnode *p) {
    struct prodrule *curr;
    int i,nkids;
    if(!p) return;
    nkids = p->nkids;
    // prodrules are maintained in linked list
    for (curr=p->prule; curr; curr=curr->next)
        preorder_semantics(curr,p);

    for (i = 0; i < nkids; i++)
        semantic_traversal(p->kids[i]);

    for (curr=p->prule; curr; curr=curr->next)
        postorder_semantics(curr,p);
}

void pre_init_list(btype bt, struct pnode *i) {
    // post order (kind of) traverse init list
    if (i->prule->code == 7602) {
        pre_init_list(bt,i->kids[0]);
        pre_init_declarator(bt,i->kids[2]);
    } else {
        pre_init_declarator(bt,i->kids[0]);
    }
}

void pre_init_declarator(btype bt, struct pnode* i) {
    token* to = NULL;
    type_el* inittype = pre_declarator(i->kids[0],&to);
    inittype = mk_type_el(bt,inittype,NULL);
    bool defined = pre_optional_init(i->kids[1]);
    environ_insert(CurrEnv(),to,inittype,false,defined);
    //TODO int size = pre_optional_init(i->kids[1]);
    //printf("btype: %d , typel: %d\n",bt,inittype->type);
}

type_el* pre_declarator(struct pnode* d,token** t) {
    // recursively build type linked list
    switch(d->prule->code) {
        case 7802: // append pointer type to type list
            return mk_type_el(
                    pointer_type,
                    NULL,
                    pre_declarator(d->kids[1],t));
            break;
        case 7801: // skipped elements
        case 7901:
            return pre_declarator(d->kids[0],t);
            break;
        case 7906: // append array type to type list
            //TODO size = *(int*)(d->kids[2]->t->lval);
            return mk_type_el(
                    array_type,
                    NULL,
                    pre_declarator(d->kids[0],t));
            break;
        case 8301:
            *t = d->t; // found token
            return NULL;
        default:
            printf("error, hit unexpected prodrule %d\n",d->prule->code);
            return NULL;
    }
}
bool pre_optional_init(struct pnode* c) {
    if (c == NULL)
        return false;
    return true;
}
