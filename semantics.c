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

type_el* mk_type_el(btype t, type_el *s, type_el *n) {
    type_el *new = sem_malloc(sizeof(type_el),0);
    new->type = t; new->sub = s; new->next = n;
    return new;
}

// lisp flashbacks
void free_type_list(type_el* head) {
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
        free_environ(prev->chl_env);
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

bool add_env_child(environ *parent) {
    if  (!parent)
        return 1;

    if ( parent->nkids < parent->ksize ) { // under max size
        parent->nkids++;
        parent->kids[parent->nkids] = mk_environ(parent,parent->depth + 1);
    }
    else { // grow the array
        short old_size = parent->ksize;
        short new_size = old_size * 2; // double in size
        // really should put a ceiling on size TODO
        environ **old = parent->kids;
        environ **new = sem_malloc(new_size * sizeof(environ*),1);
        memcpy(new,old,old_size * sizeof(environ*));
        parent->ksize = new_size;
        free(parent->kids);
        parent->kids = new;
    }
    return 0;
}

void free_environ(environ *target) {
    int i;
    short nkids;
    environ *child;
    for (i=0; i<S_SIZE; i++)
        free_table_list(target->locals[i]);
    // dont free parent, handled in tree traversal
    nkids = target->nkids; // save for future compares
    for (i=0; i<nkids; i++) {
        child = target->kids[i];
        if (child) {
            free_environ(child);
        }
    }
    // now that all taken indexes freed
    free(target->kids);
}

// hash with mod specific to semantic tables
unsigned long env_hash(char *s) {
    unsigned long hash = 5381;
    int c;
    while( (c = *s++) )
        hash = ((hash << 5) + hash) + c;
    return hash % S_SIZE;
}

environ* GetGlobal() {
    if (GlobalEnviron)
        return GlobalEnviron;
    // 'GLOBAL' environ is special case environ
    // that has no parent, i.e. root
    return mk_environ(NULL,0);
}

environ* CurrEnv() {
    if (curr_env)
        return curr_env;
    curr_env = GetGlobal();
    return curr_env;
}

void PrintCurrEnv() {
    int i;
    for (i=0; i<S_SIZE; i++) {
    }
}

void PushCurrEnv() {
    env_el *new = sem_malloc(sizeof(env_el),0);
    new->env = curr_env;
    new->next = env_stack;
    env_stack = new;
}

environ* PopEnv() {
    env_el* del = env_stack;
    env_stack = env_stack->next;
    environ *res = del->env;
    free(del);
    return res;
}
