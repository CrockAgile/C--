lex.yy.c: spec.l
		flex spec.l

spec.tab.c spec.tab.h:	spec.y
		bison -vd spec.y

parser: lex.yy.o y.tab.o
		$(cc) -o parser lex.yy.o y.tab.o

lex.yy.o: lex.yy.c spec.tab.h
		$(cc) -c lex.yy.c
