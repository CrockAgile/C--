#ifndef SEMANTICS_H
#define	SEMANTICS_H

#define S_SIZE 1024

enum SemanticNodes {
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
};

struct type {
    enum {
        int_type,
        bool_type,
        void_type,
        class_type,
        array_type,
        char_type,
        double_type,
    } kind;

};

struct typeList {
    struct type *first;
    struct typeList *rest;
};

struct table_entry {
    char *name;
    int scope;
};

struct type* IntegerType();
struct type* BooleanType();
struct type* VoidType();
struct type* CharacterType();
struct type* DoubleType();

struct type *integerType;
struct type *boolType;
struct type *voidType;
struct type *charType;
struct type *doubleType;

#endif	

