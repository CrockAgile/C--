#ifndef taclib
#define taclib

typedef enum opcode {
    CALL,
    RET,
    GTO,
    NEWO,
    DEL,
    PINT,
    PCHAR,
    PDOUB,
    PSTR,
    ADD,
    ADDF,
    SUB,
    SUBF,
    MUL,
    MULF,
    DIV,
    DIVF,
    MOD,
    LT,
    GT,
    LE,
    GE,
    EQQ,
    NE,
    OR,
    AND,
    NOT,
    LSTR,
    RSTR,
    ADDR,
    ASN,
    LARR,
    RARR,
    LMEM,
    RMEM,
    IFF,
    ERR,
} opcode;

typedef enum region {
    GLOBAL,
    PARAM,
    LOCAL,
} region;

typedef struct address {
    enum region region;
    int offset;
    int size;
} address;

typedef struct op {
    char *name;
    opcode code;
    address address[3];
    struct op *next;
} op;

void code_generate(struct pnode *n);
void print_op(FILE *stream, op *op);
void print_code(FILE *stream, op *op);
void op_append(op *src, op *des);
void tac_traversal(struct pnode *n);

int global_offset;
int param_offset;
int local_offset;

#endif
