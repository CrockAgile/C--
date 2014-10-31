#include "types.h"

void* sem_malloc(int size, bool zero) {
    void* new = NULL;
    zero ? (new = calloc(1,size)) : (new = malloc(size));
    if (!new){
        fprintf(stderr,"Memory allocation failed in Semantic Analysis\n");
        exit(3);
    }
    return new;
}

type_el* get_type(btype word) {
    if (!type_array[word]) {
        type_el* new = sem_malloc(sizeof(type_el),0);
        new->type = word;
        new->sub = NULL;
        new->next = NULL;
        type_array[word] = new;
    }
    return type_array[word];
}
