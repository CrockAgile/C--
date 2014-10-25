#ifndef SEMANTICS_H
#define	SEMANTICS_H

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

void* sem_malloc(int size, int zero);

typedef enum btype{
        int_type,
        bool_type,
        void_type,
        class_type,
        array_type,
        char_type,
        double_type,
        pointer_type
} btype;

typedef struct tab_el {
    char *name;
    int scope;
    btype type;
    int cons;
    struct tab_el *next;
} tab_el;

typedef struct environ {
    tab_el **table;
    struct environ *up;
} environ;

tab_el* MakeTableE(char*,int,btype,int,tab_el*);
environ* MakeEnviron(environ *parent);
tab_el* InsertTE(environ*,char*,int,btype,int);
tab_el* LookUpTE(environ*,char*);

#endif	

