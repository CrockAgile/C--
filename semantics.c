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
            printf("()");
            break;
        case array_type:
            printf("[]");
            break;
        case int_type:
            printf("int");
            break;
        case void_type:
            printf("void");
            break;
        case class_name:
            printf("class_instance");
            break;
        case char_type:
            printf("char");
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
    new->tok = t; new->type = ty; new->par_env = p;
    new->next = n; new->ch_env = NULL; // no child yet
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
    while (res) {
        if (!strcmp(key,res->tok->text)) {
            return res;
        }
        res = res->next;
    }
    return NULL;
}

bool environ_insert(environ *e, token *to, type_el *ty, bool c, bool d) {
    unsigned long index = env_hash(to->text);
    table_el** des = &(e->locals[index]);
    // if already in table, error
    table_el *res = environ_lookup(e,to->text);
    if (res) {
        fprintf(stderr,"error: redefinition of %s at %s:%d\n",
                to->text,to->filename,to->lineno);
        fprintf(stderr,"previous definition at %s:%d\n",
                res->tok->filename,res->tok->lineno);
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
    if(sem_cleanup) { // artificial semantics need cleanup
      sem_cleanup = 0;
      environ *gl = GetGlobal();
      token *t;
      t = environ_lookup(gl,"cin") -> tok;
      free(t);
      t = environ_lookup(gl,"cout") -> tok;
      free(t);
      t = environ_lookup(gl,"endl") -> tok;
      free(t);
      t = environ_lookup(gl,"string") -> tok;
      free(t);
      t = environ_lookup(gl,"fstream") -> tok;
      free(t);
    }
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
    if (!GlobalEnviron) { // singleton?
        GlobalEnviron = mk_environ(NULL,0);

    }
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
    printf("%*s%d:",curr->depth*2, " ",curr->depth);
    for (i=0; i<S_SIZE; i++) {
        res = curr->locals[i];
        if (res) {
            printf(" '%s' (%d,%d,",res->tok->text,i,res->defd);
            print_type_list(res->type);
            printf(") |");
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

void LinkCurrEnv(token *t) {
    table_el *res;
    env_el *new = sem_malloc(sizeof(env_el),0);
    environ *n,*old_curr = CurrEnv();
    new->env = old_curr;
    new->next = env_stack;
    env_stack = new;

    n = add_env_child(old_curr);
    res = environ_lookup(CurrEnv(),t->text);
    res->ch_env = n; // link new child

    curr_env = n;
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

void pre_semantics(struct prodrule *p, struct pnode* n){
    btype bt; token* to; type_el* types;
    switch(p->code / 10) {
      case start_state:
        iostream_included = 0;
        if ( include_success ) {
          include_success = 0;
          sem_cleanup = 1;
          token *cin_tok = mktoken(-1, "cin", 0, "iostream", "cin");
          type_el *tcin = mk_type_el(class_name,NULL,NULL);
          environ_insert(CurrEnv(),cin_tok,tcin,true,true);
          token *cout_tok = mktoken(-1, "cout", 0, "iostream", "cout");
          type_el *tout = mk_type_el(class_name,NULL,NULL);
          environ_insert(CurrEnv(),cout_tok,tout,true,true);
          token *endl_tok = mktoken(-1, "endl", 0, "iostream", "\n");
          type_el *tendl = mk_type_el(char_type,NULL,NULL);
          environ_insert(CurrEnv(),endl_tok,tendl,true,true);
          // TODO class inserts
          token *string_tok = mktoken(-1, "string", 0, "iostream", "string");
          type_el *string_type = mk_type_el(class_type,NULL,NULL);
          environ_insert(CurrEnv(),string_tok,string_type,true,true);
          token *fstream_tok = mktoken(-1, "fstream", 0, "iostream", "fstream");
          type_el *fstream_type = mk_type_el(class_type,NULL,NULL);
          environ_insert(CurrEnv(),fstream_tok,fstream_type,true,true);
        }
        break;
        case member_declaration:
            bt = n->kids[0]->t->code;
            pre_decl_list(bt,n->kids[1]);
            break;
        case class_specifier:
            types = mk_type_el(class_type,NULL,NULL);
            to = n->kids[0]->kids[1]->t;//spec->class_head->'name'
            environ_insert(CurrEnv(),to,types,false,true);
            LinkCurrEnv(to);
            break;
        case compound_statement:
            PushCurrEnv();
            break;
        case simple_declaration:
            bt = n->kids[0]->t->code;
            pre_decl_list(bt,n->kids[1]);
            break;
        case function_definition:
            bt = n->kids[0]->t->code;
            types = pre_declarator(n->kids[1],bt,&to);
            environ_insert(CurrEnv(),to,types,false,true);
            break;
    }
}

void post_semantics(struct prodrule *p, struct pnode* n){
    switch(p->code / 10) {
        case start_state:
            break;
        case class_specifier:
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
        pre_semantics(curr,p);

    for (i = 0; i < nkids; i++)
        semantic_traversal(p->kids[i]);

    for (curr=p->prule; curr; curr=curr->next)
        post_semantics(curr,p);
}

void pre_decl_list(btype bt, struct pnode *i) {
    // post order (kind of) traverse init list
    int c = i->prule->code;
    if (c == 7602 || c == 10002 ) {
        pre_decl_list(bt,i->kids[0]);
        pre_init_declarator(bt,i->kids[2]);
    } else {
        pre_init_declarator(bt,i->kids[0]);
    }
}

void pre_init_declarator(btype bt, struct pnode* i) {
    token* to = NULL;
    type_el* inittype = pre_declarator(i->kids[0],bt,&to);
    bool defined = pre_optional_init(i->kids[1]);
    // TODO printf("def? %d -> nkids: %d\n",defined,i->nkids);
    environ_insert(CurrEnv(),to,inittype,false,defined);
    //TODO int size = pre_optional_init(i->kids[1]);
}

type_el* pre_declarator(struct pnode* d,btype ty, token** t) {
    // recursively build type linked list
    switch(d->prule->code) {
        case 7802: // append pointer type to type list
            return mk_type_el(
                    pointer_type,
                    NULL,
                    pre_declarator(d->kids[1],ty,t));
            break;
        case 7905: // function prototype
            return mk_type_el(
                    function_type,
                    NULL,
                    pre_declarator(d->kids[0],ty,t));
            break;
        case 7906: // append array type to type list
            //TODO set the size of the array
            return mk_type_el(
                    array_type,
                    NULL,
                    pre_declarator(d->kids[0],ty,t));
            break;
        case 8301:
            *t = d->t; // found token
            return NULL;
        case 7801:
            return mk_type_el(
                    ty,
                    NULL,
                    pre_declarator(d->kids[0],ty,t));
            break;
        case 7901: // skipped elements
            return pre_declarator(d->kids[0],ty,t);
            break;
        default:
            printf("error, hit unexpected prodrule %d\n",d->prule->code);
            return NULL;
    }
}
// TODO actually initialize values
bool pre_optional_init(struct pnode* c) {
    if (c == NULL)
        return false;
    return true;
}
