#ifndef TYPES_H
#define TYPES_H

#include "stdbool.h"

void* sem_malloc(int size, bool zero);

typedef enum btype{
        int_type,
        bool_type,
        void_type,
        char_type,
        double_type,
        class_type,
        // complicated linked types
        pointer_type,
        function_type,
        array_type,
        // always keep nil last for correct
        // array size, see below
        nil_type
} btype;

typedef struct type_el {
    btype type;
    struct type_el *sub;
    struct type_el *next;
} type_el;

type_el* type_array[nil_type];
type_el* get_type(btype word);

#endif
