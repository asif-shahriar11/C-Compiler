%option noyywrap

%x STRING
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT

%{
#include<iostream>
#include<fstream>
#include<string>
#include "SymbolTable.cpp"

int line_count = 1;
int errorCount = 0;
int stringStartLine;
int commentStartLine;

FILE *logout;
FILE *tokenout;

SymbolTable symbolTable(7);

char ch;

string str;
string comment;

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z_]
DIGIT [0-9]
NEWLINE \n
SPACE [ ]
BACKSLASH "\\"
SPECIAL_CHARACTER "\\[tvar"'afb0n]"|"\\""

%%

{WHITESPACE} {}

{NEWLINE} {line_count++;}


"if"	{
			fprintf(tokenout, " <IF> ");
			fprintf(logout, "Line no %d: TOKEN <IF> Lexeme %s found\n", line_count, yytext);
}
		
"else"	{
			fprintf(tokenout," <ELSE> ");
			fprintf(logout, "Line no %d: TOKEN <ELSE> Lexeme %s found\n", line_count, yytext);
}

"for"   {
            fprintf(tokenout," <FOR> ");
			fprintf(logout, "Line no %d: TOKEN <FOR> Lexeme %s found\n", line_count, yytext);
}

"loop"   {
            fprintf(tokenout," <LOOP> ");
			fprintf(logout,"Line no %d: TOKEN <LOOP> Lexeme %s found\n",line_count,yytext);
}

"do"   {
            fprintf(tokenout," <DO> ");
			fprintf(logout,"Line no %d: TOKEN <DO> Lexeme %s found\n",line_count,yytext);
}

"break"   {
            fprintf(tokenout," <BREAK> ");
			fprintf(logout,"Line no %d: TOKEN <BREAK> Lexeme %s found\n",line_count,yytext);
}

"int"   {
            fprintf(tokenout," <INT> ");
			fprintf(logout,"Line no %d: TOKEN <INT> Lexeme %s found\n",line_count,yytext);
}

"char"   {
            fprintf(tokenout," <CHAR> ");
			fprintf(logout,"Line no %d: TOKEN <CHAR> Lexeme %s found\n",line_count,yytext);
}

"float"   {
            fprintf(tokenout," <FLOAT> ");
			fprintf(logout,"Line no %d: TOKEN <FLOAT> Lexeme %s found\n",line_count,yytext);
}

"double"   {
            fprintf(tokenout," <DOUBLE> ");
			fprintf(logout,"Line no %d: TOKEN <DOUBLE> Lexeme %s found\n",line_count,yytext);
}

"void"   {
            fprintf(tokenout," <VOID> ");
			fprintf(logout,"Line no %d: TOKEN <VOID> Lexeme %s found\n",line_count,yytext);
}

"return"   {
            fprintf(tokenout," <RETURN> ");
			fprintf(logout,"Line no %d: TOKEN <RETURN> Lexeme %s found\n",line_count,yytext);
}

"switch"   {
            fprintf(tokenout," <SWITCH> ");
			fprintf(logout,"Line no %d: TOKEN <SWITCH> Lexeme %s found\n",line_count,yytext);
}

"case"   {
            fprintf(tokenout," <CASE> ");
			fprintf(logout,"Line no %d: TOKEN <CASEE> Lexeme %s found\n",line_count,yytext);
}

"default"   {
            fprintf(tokenout," <DEFAULT> ");
			fprintf(logout,"Line no %d: TOKEN <DEFAULT> Lexeme %s found\n",line_count,yytext);
}

"continue"   {
            fprintf(tokenout," <CONTINUE> ");
			fprintf(logout,"Line no %d: TOKEN <CONTINUE> Lexeme %s found\n",line_count,yytext);
}


[+-]		{
			fprintf(tokenout," <ADDOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <ADDOP> Lexeme %s found\n",line_count,yytext);
}

[*/%]	{
			fprintf(tokenout," <MULOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <MULOP> Lexeme %s found\n",line_count,yytext);
}

("++"|"--")		{
			fprintf(tokenout," <INCOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <INCOP> Lexeme %s found\n",line_count,yytext);
}

("<"|"<="|">"|">="|"=="|"!=")		{
			fprintf(tokenout," <RELOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <RELOP> Lexeme %s found\n",line_count,yytext);
}

"="		{
			fprintf(tokenout," <ASSIGNOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
}

("&&"|"||"|"!")		{
			fprintf(tokenout," <LOGICOP, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LOGICOP> Lexeme %s found\n",line_count,yytext);
}

"("		{
			fprintf(tokenout," <LPAREN, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LPAREN> Lexeme %s found\n",line_count,yytext);
}

")"		{
			fprintf(tokenout," <RPAREN, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <RPAREN> Lexeme %s found\n",line_count,yytext);
}

"{"		{
			fprintf(tokenout," <LCURL, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LCURL> Lexeme %s found\n",line_count,yytext);
            symbolTable.enterScope();
}

"}"		{
			fprintf(tokenout," <RCURL, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <RCURL> Lexeme %s found\n",line_count,yytext);
            symbolTable.exitScope();
}

"["		{
			fprintf(tokenout," <LTHIRD, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <LTHIRD> Lexeme %s found\n",line_count,yytext);
}

"]"		{
			fprintf(tokenout," <RTHIRD, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <RTHIRD> Lexeme %s found\n",line_count,yytext);
}

","		{
			fprintf(tokenout," <COMMA, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <COMMA> Lexeme %s found\n",line_count,yytext);
}

";"		{
			fprintf(tokenout," <SEMICOLON, %s> ",yytext);
			fprintf(logout,"Line no %d: TOKEN <SEMICOLON> Lexeme %s found\n",line_count,yytext);
}
		
{DIGIT}+ 	{
				fprintf(tokenout," <CONST_INT, %s> ",yytext);
				fprintf(logout,"Line no %d: TOKEN <CONST_INT> Lexeme %s found\n",line_count,yytext);
                symbolTable.insert(logout,"CONST_INT",yytext);
                symbolTable.printAllScopeTable(logout);
}

{DIGIT}*(\.{DIGIT}+) {
                fprintf(tokenout," <CONST_FLOAT, %s> ",yytext);
				fprintf(logout,"Line no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
				symbolTable.insert(logout,"CONST_FLOAT",yytext);
                symbolTable.printAllScopeTable(logout);
}


{DIGIT}*(\.{DIGIT}+)([Ee][+-]({DIGIT}+)) 	{
				fprintf(tokenout," <CONST_FLOAT, %s> ",yytext);
				fprintf(logout,"Line no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
				symbolTable.insert(logout,"CONST_FLOAT",yytext);
                symbolTable.printAllScopeTable(logout);
}

{DIGIT}*(\.{DIGIT}*)(\.{DIGIT}*)+	{
				errorCount++;
				fprintf(logout,"Error at line %d: Too many decimal point for character sequence %s\n",line_count,yytext);
}

{DIGIT}*(\.{DIGIT}*)?([Ee][+-]?{DIGIT}*)(\.{DIGIT}*)+	{
				errorCount++;
				fprintf(logout,"Error at line %d: Ill formed number %s\n",line_count,yytext);
}


\'({LETTER}|{DIGIT})\'    {
                fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
				fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
				symbolTable.insert(logout,"CONST_CHAR",yytext);
                symbolTable.printAllScopeTable(logout);
}

\'\\n\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\t\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\\\\' {
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\\'\' {
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\\"\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\a\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\f\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\r\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\b\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\v\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\\0\' { 
        fprintf(tokenout," <CONST_CHAR, %s> ",yytext);
		fprintf(logout,"Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
		symbolTable.insert(logout,"CONST_CHAR",yytext);
        symbolTable.printAllScopeTable(logout);
}

\'\'    {
        errorCount++;
		fprintf(logout,"Error at line %d: Empty character constant error %s\n",line_count,yytext);
}

\'({LETTER}|{DIGIT}|{SPACE}|{BACKSLASH}|{SPECIAL_CHARACTER})({LETTER}|{DIGIT}|{SPACE}|{BACKSLASH}|{SPECIAL_CHARACTER})+\'   {
        errorCount++;
		fprintf(logout,"Error at line %d: Multiple characters error %s\n",line_count,yytext);
}

\'({LETTER}|{DIGIT}|{SPACE}|{BACKSLASH}|{SPECIAL_CHARACTER})*    {
        errorCount++;
		fprintf(logout,"Error at line %d: Unfinished character error %s\n",line_count,yytext);
}



{LETTER}({LETTER}|{DIGIT})* {
                fprintf(tokenout," <ID, %s> ",yytext);
				fprintf(logout,"Line no %d: TOKEN <ID> Lexeme %s found\n",line_count,yytext);
				symbolTable.insert(logout, "ID",yytext);
                symbolTable.printAllScopeTable(logout);
}

({DIGIT})+{LETTER}({LETTER}|{DIGIT})* {
                errorCount++;
				fprintf(logout,"Error at line %d: Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence %s\n",line_count,yytext);
}

\"  {
        BEGIN STRING;
        str.clear();
        str.push_back(34);
        stringStartLine = line_count;
}



<STRING>\\\n   {line_count++; str.push_back('\n');}

<STRING>"\\n"	{str.push_back('\n');}

<STRING>"\\t"	{str.push_back('\t');}

<STRING>"\\\\"	{str.push_back(92);}

<STRING>"\\\'"	{str.push_back(39);}

<STRING>"\\\""	{str.push_back(34);}

<STRING>"\\a"	{str.push_back('\a');}

<STRING>"\\f"	{str.push_back('\f');}

<STRING>"\\r"	{str.push_back('\r');}

<STRING>"\\b"	{str.push_back('\b');}

<STRING>"\\v"	{str.push_back('\v');}

<STRING>"\\0"	{str.push_back('\0');}

<STRING>\n  {
            line_count++;
            errorCount++;
            fprintf(logout,"Error at line %d: Unfinished string %s\n",stringStartLine,str.c_str());
            BEGIN INITIAL;
}

<STRING>\" {
            str.push_back(34);
            fprintf(tokenout," <STRING, %s> ",str.c_str());
		    fprintf(logout,"Line no %d: TOKEN <STRING> Lexeme %s found\n",stringStartLine,str.c_str());
            BEGIN INITIAL;
}

<STRING>.   {str.append(yytext);}


"//"    {
            BEGIN SINGLE_LINE_COMMENT;
            comment.clear();
			comment.append(yytext);
            commentStartLine = line_count;
}

<SINGLE_LINE_COMMENT>\\\n   {
            line_count++;
            comment.append(yytext);
}

<SINGLE_LINE_COMMENT>\n     {
            line_count++;
            comment.append(yytext);
            fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s foundstr\n",commentStartLine,comment.c_str());
            BEGIN INITIAL;
}

<SINGLE_LINE_COMMENT><<EOF>>    {
            fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s foundstr\n",commentStartLine,comment.c_str());
            BEGIN INITIAL;
            return 0;
}

<SINGLE_LINE_COMMENT>.  {comment.append(yytext);}


"/*"    {
            BEGIN MULTI_LINE_COMMENT;
            comment.clear();
			comment.append(yytext);
            commentStartLine = line_count;
}

<MULTI_LINE_COMMENT>\n	{
            line_count++;
            comment.append(yytext);
}

<MULTI_LINE_COMMENT>"*/"	{
            line_count++;
            comment.append(yytext);
            fprintf(logout,"Line no %d: TOKEN <COMMENT> Lexeme %s found\n",commentStartLine,comment.c_str());
            BEGIN INITIAL;
}



<MULTI_LINE_COMMENT><<EOF>>	{
			errorCount++;
            fprintf(logout,"Error at line %d: Unterminated comment %s\n",commentStartLine,comment.c_str());
			return 0;
}

<MULTI_LINE_COMMENT>.	{comment.append(yytext);}

.	{
		errorCount++;
		fprintf(logout,"\nError at line %d: Unrecognized character %s\n",line_count,yytext);
}
		

%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("1805040_log.txt","w");
	tokenout= fopen("1805040_token.txt","w");

	yyin= fin;
	yylex();
	symbolTable.printAllScopeTable(logout);
    fprintf(logout,"\nTotal Lines: %d\n",line_count);
	fprintf(logout,"\nTotal Errors: %d\n",errorCount);
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}