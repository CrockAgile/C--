# Limited Initial Makefile
# Creates "120++" from "lexer.l" and "120++.c"
#

CC=gcc
CFLAGS=-c -g

120++:	120++.o lex.yy.o lexlib.o
	$(CC) -o 120++ 120++.o lex.yy.o lexlib.o

120++.o: 120++.c
	$(CC) $(CFLAGS) 120++.c

lex.yy.o: lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c

lex.yy.c: lexer.l cgram.tab.h
	flex lexer.l
lexlib.o: lexlib.c
	$(CC) $(CFLAGS) lexlib.c
clean:
	rm *.o 120++ lex.yy.c
