#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "semantics.h"

void* sem_malloc(int size, int zero) {
    void* new = NULL;
    zero ? (new = calloc(1,size)) : (new = malloc(size));
    if (!new){
        fprintf(stderr,"Memory allocation failed in Semantic Analysis\n");
        exit(3);
    }
    return new;
}

tab_el* MakeTableE(char*name,int scope,btype type,int cons,tab_el*next){
    tab_el* new = sem_malloc(sizeof(tab_el),0);
    new->name = strdup(name);
    new->scope = scope;
    new->type = type;
    new->cons = cons;
    new->next = next;
    return new;
}

environ* MakeEnviron(environ *parent) {
    environ *new = sem_malloc(sizeof (environ),0);
    new->up = parent;
    new->table = sem_malloc(S_SIZE * sizeof (environ*),0);
    return new;
}

tab_el* InsertTE(environ* env,char*k,int scope,btype type,int c) {
}

tab_el* LookUp(environ *curr, char *key) {
}

