# A Subset C Compiler

This is a simple compiler for a subset of the C programming language. Given a .c input file, this compiler scans the .c file for specific tokens, then performs a syntactic and semantic analysis, and finally,
if the source code does not contain any lexical, syntax or semantic error, generates assembly code for Intel 8086 assembly language.

## 1. Symbol Table

A symbol-table is a data structure maintained by
the compilers in order to store information about the occurrence of various entities such
as identifiers, objects, function names etc. Information of different entities may include
type, value, scope etc. At the starting phase of constructing a compiler, we will construct
a symbol-table which maintains a list of hash tables where each hash table contains
information of symbols encountered in a scope of the source program.


## 2. Lexical Analyzer (Scanner)

Lexical analysis is the process of 
scanning the source program as a sequence of characters and converting them into sequences of 
tokens. A program that performs this task is called a lexical analyzer or a lexer or a scanner. For 
example, if a portion of the source program contains int x=5; the scanner would convert in a 
sequence of tokens like <INT><ID,x><ASSIGNOP,=><COST_NUM,5><SEMICOLON>. The task of lexical analysis is performed using a tool named flex (Fast 
Lexical Analyzer Generator) which is a popular tool for generating scanners.

## 3. Syntax and Semantic Analyzer (Parser)

This is the last part of the front end of a compiler for a subset of the C
language. In this step we perform syntax analysis and semantic analysis with a grammar rule
containing function implementation. To do so, we build a parser with the help
of Lex (Flex) and Yacc (Bison).

### Syntax analysis:

- Incorporating the specified grammar for the subset of C language (variables, funnction declaration and definition, conditional statements, loops, arrays, expressions)
- Handling ambiguity of the specified grammar
- Printing appropriate error messages for syntax errors

### Semantic analysis:

- Type checking (assignment consistency, indexing, operands)
- Type conversion
- Uniqueness checking
- Function declaration-definition and parameters consistency

## 4. Intermediate Code Generation (ICG)

After performing syntax and semantic analysis, we now generate  intermediate code for 
a source program having no error. If there were any error, they would have been captured in the previous steps. The Intel 8086 assembly language is selected for intermediate representation.


