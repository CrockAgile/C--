struct pnode {
    int prodrule;
    int nkids;
    struct pnode *kids[9];
    struct token *leaf;
};

enum {
    CLASS_HEAD_RULE_1,
};
