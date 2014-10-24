Class long project for CS 445: Compiler Design

Last Edited: 10/22/2014

TODOs:
    Prepopulate Symbol Table
	- cin,cout,endl,string

    Symbol Table Scope
	- Find grammar Blocks
	- Stack of name tables

    Type Checking
	- Write out 120++ cases following Coursera Notation
	- Should leaves be built with types if possible? (ICON prob, not decl)
	- Two Phases
	    - Top to Bot, then Bot leaves up

    Separate out dependencies (parse.h vs lex.h vs ??)
    
    Improve Lexical Errors
        - Line Numbers
        - Column Number, specific character
        - Expectations?

    Enforce Character Constants
        - 'c' vs 'cccc'

    Transition Lexer to Built-in Flex buffer state stack
        - Dynamic Buffer

    String Limitations (length)
