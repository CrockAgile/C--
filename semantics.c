#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "semantics.h"

void* sem_malloc(int size, bool zero) {
    void* new = NULL;
    zero ? (new = calloc(1,size)) : (new = malloc(size));
    if (!new){
        fprintf(stderr,"Memory allocation failed in Semantic Analysis\n");
        exit(3);
    }
    return new;
}

environ* MakeEnviron(environ *parent) {
    environ *new = sem_malloc(sizeof (environ),0);
    new->up = parent;
    new->vars = sem_malloc(sizeof (type_el*) * S_SIZE, 1);
    new->vars = sem_malloc(sizeof (type_el*) * S_SIZE, 1);
    return new;
}

table_el* InsertTableEl(environ* env,char*k,int scope,btype type,int c) {
    return NULL;
}

table_el* LookUpTableEl(environ *curr, char *key) {
    return NULL;
}

