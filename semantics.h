#ifndef SEMANTICS_H
#define	SEMANTICS_H

#include <stdbool.h>
#define S_SIZE 1024

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
} btype;

typedef struct type_el {
    btype type;
    struct type_el *sub;
} type_el;

struct environ;

typedef struct table_el {
    // needed by Vars, Funcs, and Classes
    char *name;
    struct environ *pscope;
    type_el *type;
    bool cons;
    bool defined;
    // needed by Funcs, and Classes
    type_el *param_types;
    struct environ *cscope;
    struct table_el *next;
} table_el;

typedef struct environ {
    table_el **vars;
    table_el **classes;
    struct environ *up;
} environ;

table_el* MakeTableEl(char*,int,type_el*,int);
environ* MakeEnviron(environ *parent);
table_el* InsertTableEl(environ*,char*,int,btype,int);
table_el* LookUpTableEl(environ*,char*);

#endif	

