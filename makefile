# Makefile for 120++ 
# Jeff Crocker

CC=gcc
CFLAGS=-c -g
TARNAME=hw2.tar

120++:	120++.o lex.yy.o lexlib.o
	$(CC) -o 120++ 120++.o lex.yy.o lexlib.o
	cp 120++ ./examples/120++

120++.o: 120++.c
	$(CC) $(CFLAGS) 120++.c

lex.yy.o: lex.yy.c
	$(CC) $(CFLAGS) lex.yy.c

lex.yy.c: lexer.l cgram.tab.h
	flex lexer.l
lexlib.o: lexlib.c
	$(CC) $(CFLAGS) lexlib.c
clean:
	rm -f *.o 120++ lex.yy.c
tar: clean
	tar -cvf $(TARNAME) . \
		--exclude=./.git/* \
		--exclude=./.git \
		--exclude=$(TARNAME) \
		--exclude=.gitignore
transfer:
	scp $(TARNAME) croc4574@wormulon.cs.uidaho.edu:/home/croc4574/445/$(TARNAME)
