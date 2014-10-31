#ifndef ENV_H
#define	ENV_H
#define S_SIZE 1024

#include "types.h"
#include "lex.h"

typedef enum SemanticNode {
    // nodes that require new environment
    class_specifier = 950,
    compound_statement = 510,
    selection_statement = 530,
    iteration_statement = 550,
    function_definition = 900,

    // nodes that require adding to environment
    // function_definiton previously defined
    // class_specifier also previously defined
    init_declarator = 770,
    parameter_declarator = 890,
} SemanticNode;

struct type_env;

typedef struct tenv_entry {
    enum {
        varEntry,
        funEntry,
        newEntry
    } kind;
    union {
        struct {
            type_el *type;
        } var;
        struct {
            type_el *params;
            type_el *result;
        } fun;
    } u;
} tenv_entry;

typedef struct type_env {
} type_env;

#endif
