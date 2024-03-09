%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include "SymbolTable.cpp"
#include "helper.cpp"
#include<fstream>

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

FILE *logout;
FILE *errorout;
FILE *fp;

extern int line_count;
extern int errorCount;

SymbolInfo *symbolInfo;
SymbolTable symbolTable(7);

bool isValid; 

bool isVoid;

string variableType;



void yyerror(const char *s)
{
	errorCount++;
	fprintf(logout, "Error at line %d: %s\n", line_count, s);
	fprintf(errorout, "Error at line %d: %s\n", line_count, s);
}


%}

%union 
{
	SymbolInfo* var;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON PRINTLN

%token <var> ADDOP
%token <var> MULOP
%token <var> RELOP
%token <var> LOGICOP
%token <var> CONST_INT
%token <var> CONST_FLOAT
%token <var> CONST_CHAR
%token <var> ID
%token <var> STRING

%type <var> start program unit var_declaration variable type_specifier declaration_list
%type <var> expression_statement func_declaration parameter_list func_definition
%type <var> compound_statement statements unary_expression factor statement arguments
%type <var> expression logic_expression simple_expression rel_expression term argument_list
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		fprintf(logout,"Line %d: start : program\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());

		symbolTable.printAllScopeTable(logout);
		fprintf(logout, "\nTotal lines: %d\n", line_count);
		fprintf(logout, "Total errors: %d\n", errorCount);
	}
	;

program : program unit 
	{
		fprintf(logout,"Line %d: program : program unit\n",line_count);
		$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "program");
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| unit
	{
		fprintf(logout,"Line %d: program : program unit\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	
unit : var_declaration
	{
		fprintf(logout,"Line %d: unit : var_declaration\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
    | func_declaration
	{
		fprintf(logout,"Line %d: unit : func_declaration\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
    | func_definition
	{
		fprintf(logout,"Line %d: unit : func_definition\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
    ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			SymbolInfo* func = symbolTable.lookUp($2->getName());
			if(func == nullptr) {
				vector<string> type;
				vector<SymbolInfo*> pList;
				vector<string> pair = splitString($4->getName(), ',');
				for(string currentPair:pair) {
					type = splitString(currentPair, ' ');
					pList.push_back(new SymbolInfo("name", type[0]));
				}
				
				symbolTable.insert(new SymbolInfo($2->getName(), $1->getName(), pList));
				
				//SymbolInfo *s = new SymbolInfo($2->getName(), $1->getName());
				//s->setIdentity("function");
				//s->parameterList = $4->parameterList;
				//symbolTable.insert(s);
			}
			else {
				errorCount++;
				fprintf(logout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
				fprintf(errorout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
			}
			fprintf(logout,"Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n",line_count);
			$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ");", "func_declaration");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			SymbolInfo* func = symbolTable.lookUp($2->getName());
			if(func == nullptr) {
				SymbolInfo *s = new SymbolInfo($2->getName(), $1->getName());
				s->setIdentity("function");
				symbolTable.insert(s);
			}
			else {
				errorCount++;
				fprintf(logout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
				fprintf(errorout, "Error at line %d: function %s already declared\n", line_count, $2->getName().c_str());
			}
			fprintf(logout,"Line %d: func_declaration : type_specifier ID RPAREN SEMICOLON\n",line_count);
			$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
				{
					SymbolInfo* func = symbolTable.lookUp($2->getName());
					vector<SymbolInfo*> pList;
					// setting pList
					vector<string> pair = splitString($4->getName(), ',');
					vector<string> typeName;
					for(string currentPair:pair) {
						typeName = splitString(currentPair, ' ');
						SymbolInfo* tempSymbol = new SymbolInfo(typeName[1], typeName[0]);
						pList.push_back(tempSymbol);
					}
					//
					// note - pList works fine
					if(func == nullptr) {
						//SymbolInfo *s1 = new SymbolInfo($2->getName(), $1->getName(), pList);
						//s1->setParameterList(pList); 
						//for(int i=0; i<pList.size(); i++)	s1->getParameterList().push_back(pList[i]);
						//s1->setIdentity("function");
						//s1->setFunctionDefined(true);
						symbolTable.insert(new SymbolInfo($2->getName(), $1->getName(), pList, true));
						// cout << "here " << s1->getParameterList().size() << endl; works fine
						//for(int i=0; i< (s1->getParameterList().size()); i++)	cout << "hrer" << s1->getParameterList()[i]->getName() << endl; // works fine
						symbolTable.enterScope();
						for(int i=0; i<(pList.size()); i++) {
							isValid = symbolTable.insert(pList[i]);
							//cout << "here " << pList[i]->getName() << endl; // ok
							if(!isValid) {
								errorCount++;
								fprintf(logout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
								fprintf(errorout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
							}
						}
						
					}
					else {
						if(func->getIdentity() == "function") {
							if(func->getFunctionDefined()) {
								errorCount++;
								fprintf(logout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
								fprintf(errorout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
							}
							else {
								int declaredParameterNum = func->getParameterList().size();
								string declaredReturnType = func->getType();
								if(declaredReturnType != $1->getName()) {
									errorCount++;
									fprintf(logout, "Error at line %d: return type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: retun type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}
								if(declaredParameterNum != pList.size()) {
									errorCount++;
									fprintf(logout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}
								else {
									for(int i=0; i<declaredParameterNum; i++) {
										if(func->getParameterList()[i]->getType() != pList[i]->getType()) {
											errorCount++;
											fprintf(logout, "Error at line %d: function %s parameter does not match with declaration\n", line_count, $2->getName().c_str());
											fprintf(errorout, "Error at line %d: function %s parameter does not match with declaration\n", line_count, $2->getName().c_str());
										}
									}
								}

								symbolTable.remove($2->getName());
								//SymbolInfo *s2 = new SymbolInfo($2->getName(), $1->getName(), pList);
								//s1->setParameterList(pList);
								//s2->setIdentity("function");
								//s2->setFunctionDefined(true);
								//symbolTable.insert(s2);
								symbolTable.insert(new SymbolInfo($2->getName(), $1->getName(), pList, true));
								symbolTable.enterScope();
								for(int i=0; i<(pList.size()); i++) {
									isValid = symbolTable.insert(pList[i]);
									if(!isValid) {
										errorCount++;
										fprintf(logout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
										fprintf(errorout, "Error at line %d: parameter of function %s already defined\n", line_count, $2->getName().c_str());
									}
								}

							}
						}
						else {
							symbolTable.enterScope();
							errorCount++;
							fprintf(logout, "Error at line %d:  %s is not a function\n", line_count, $2->getName().c_str());
							fprintf(errorout, "Error at line %d: %s is not a function\n", line_count, $2->getName().c_str());
						}
					}
					pList.clear();
				}
				compound_statement
				{
					SymbolInfo *ss = symbolTable.lookUp($2->getName());
					cout << "compound "<< ss->getIdentity() << ss->getParameterList()[0]->getType() << endl;
					fprintf(logout,"Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n",line_count);
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")" + $7->getName() + "\n", "func_definition");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
				| type_specifier ID LPAREN RPAREN
				{
					SymbolInfo* func = symbolTable.lookUp($2->getName());
					if(func == nullptr) {
						SymbolInfo *s1 = new SymbolInfo($2->getName(), $1->getName());
						s1->setIdentity("function");
						s1->setFunctionDefined(true);
						symbolTable.insert(s1);
						symbolTable.enterScope();
					}
					else {
						if(func->getIdentity() == "function") {
							if(func->getFunctionDefined()) {
								errorCount++;
								fprintf(logout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
								fprintf(errorout, "Error at line %d: function %s already defined\n", line_count, $2->getName().c_str());
							}
							else {
								int declaredParameterNum = func->getParameterList().size();
								string declaredReturnType = func->getType();
								if(declaredReturnType != $1->getName()) {
									errorCount++;
									fprintf(logout, "Error at line %d: return type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: retun type of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}
								if(declaredParameterNum != 0) {
									errorCount++;
									fprintf(logout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
									fprintf(errorout, "Error at line %d: number of parameters of function %s does not match with declaration\n", line_count, $2->getName().c_str());
								}

								symbolTable.remove($2->getName());
								SymbolInfo *s1 = new SymbolInfo($2->getName(), $1->getName());
								s1->setIdentity("function");
								s1->setFunctionDefined(true);
								symbolTable.insert(s1);
								symbolTable.enterScope();
							}
						}
						else {
							symbolTable.enterScope();
							errorCount++;
							fprintf(logout, "Error at line %d:  %s is not a function\n", line_count, $2->getName().c_str());
							fprintf(errorout, "Error at line %d: %s is not a function\n", line_count, $2->getName().c_str());
						}
					}
				}
				compound_statement
				{
					fprintf(logout,"Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n",line_count);
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $6->getName() + "\n", "func_definition");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 			;				
			


parameter_list  : parameter_list COMMA type_specifier ID
		{
			fprintf(logout,"Line %d: parameter_list  : parameter_list COMMA type_specifier ID\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName() + " " + $4->getName(), "parameter_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($4->getName(), $3->getName());
			//param->setIdentity("variable");
			//$$->parameterList.push_back(param);
		}
		| parameter_list COMMA type_specifier
 		{
			fprintf(logout,"Line %d: parameter_list  : parameter_list COMMA type_specifier\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "parameter_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($3->getName(), $3->getName());
			//param->setIdentity("type_specifier");
			//$$->parameterList.push_back(param);
		}
		| type_specifier ID
		{
			fprintf(logout,"Line %d: parameter_list  : type_specifier ID\n",line_count);
			$$ = new SymbolInfo($1->getName() + " " + $2->getName(), "parameter_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($2->getName(), $1->getName());
			//param->setIdentity("variable");
			//$$->parameterList.push_back(param);
		}
		| type_specifier
 		{
			fprintf(logout,"Line %d: parameter_list  : type_specifier\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
			//SymbolInfo* param = new SymbolInfo($1->getName(), $1->getName());
			//param->setIdentity("type_specifier");
			//$$->parameterList.push_back(param);
		}
		;




 		
compound_statement : LCURL statements RCURL
 		    {
				fprintf(logout,"Line %d: compound_statement : LCURL statements RCURL\n",line_count);
				$$ = new SymbolInfo("{\n"+ $2->getName() + "\n}", "compound_statement");
				fprintf(logout, "%s\n", $$->getName().c_str());
				symbolTable.printAllScopeTable(logout);
				symbolTable.exitScope();
			}
			| LCURL RCURL
 		    {
				fprintf(logout,"Line %d: compound_statement : LCURL RCURL\n",line_count);
				$$ = new SymbolInfo("{\n}", "compound_statement");
				fprintf(logout, "%s\n", $$->getName().c_str());
			}
			;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
 		{
			if($1->getName() == "void") {
				errorCount++;
				fprintf(logout, "Error at line %d: Variable type cannot be void\n", line_count);
				fprintf(errorout, "Error at line %d: Variable type cannot be void\n", line_count);
			}
			else {
				vector<string> line = splitString($2->getName(), ',');
				for(string word:line) {
					SymbolInfo* s;
					string name, size;
					if ((word.find("[") != string::npos) || (word.find("]") != string::npos)) {
						stringstream ss(word);
						getline(ss, name, '[');
						while(getline(ss, size, '[')) { }
						stringstream ss2(size);
						getline(ss2, size, ']');

						int sz = atoi(size.c_str());
						s = new SymbolInfo(name, $1->getType(), sz);
						s->setIdentity("array");
    				}
					else {
						s = new SymbolInfo(word, $1->getType());
						s->setIdentity("variable");
					}
					isValid = symbolTable.insert(s);
					if(!isValid) {
						errorCount++;
						fprintf(logout, "Error at line %d: %s variable already exists\n", line_count, s->getName().c_str());
						fprintf(errorout, "Error at line %d: %s variable already exists\n", line_count, s->getName().c_str());
					}
				}
			}
			
			fprintf(logout,"Line %d: var_declaration : type_specifier declaration_list SEMICOLON\n",line_count);
			$$ = new SymbolInfo($1->getName() + $2->getName() + ";", "var_declaration");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
 		 
type_specifier	: INT
				{
					fprintf(logout,"Line %d: type_specifier	: INT\n",line_count);
					$$ = new SymbolInfo("int", "int");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 				| FLOAT
				{
					fprintf(logout,"Line %d: type_specifier	: FLOAT\n",line_count);
					$$ = new SymbolInfo("float", "float");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 				| VOID
				{
					fprintf(logout,"Line %d: type_specifier	: VOID\n",line_count);
					$$ = new SymbolInfo("void", "void");
					fprintf(logout, "%s\n", $$->getName().c_str());
				}
 				;
 		
declaration_list : declaration_list COMMA ID
		{
			fprintf(logout,"Line %d: declaration_list : declaration_list COMMA ID\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "declaration_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		{
			fprintf(logout,"Line %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n",line_count);
			$$ = new SymbolInfo($1->getName() + "," + $3->getName() + "[" + $5->getName() + "]", "declaration_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| ID
 		{
			fprintf(logout,"Line %d: declaration_list : ID\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}	
		| ID LTHIRD CONST_INT RTHIRD
 		{
			fprintf(logout,"Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n",line_count);
			$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "declaration_list");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}  
		;
 		  
statements : statement
		{
			fprintf(logout,"Line %d: statements : statement\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
	   | statements statement
	   {
			fprintf(logout,"Line %d: statements : statements statement\n",line_count);
			$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "statements");
			fprintf(logout, "%s\n", $$->getName().c_str());
	   }
	   ;
	   
statement : var_declaration
	{
		fprintf(logout,"Line %d: statement : var_declaration\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}	
	| expression_statement
	{
		fprintf(logout,"Line %d: statement : expression_statement\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| { symbolTable.enterScope(); }compound_statement
	{
		fprintf(logout,"Line %d: statement : compound_statement\n",line_count);
		$$ = $2;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		fprintf(logout,"Line %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n",line_count);
		$$ = new SymbolInfo("for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName(),	"statement");
		fprintf(logout, "%s\n", $$->getName().c_str());
	}  
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		fprintf(logout,"Line %d: statement : IF LPAREN expression RPAREN statement\n",line_count);
		$$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName(), "statement");
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		fprintf(logout,"Line %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n",line_count);
		$$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName() + "else" + $7->getName(), "statement");
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| WHILE LPAREN expression RPAREN statement
	{
		fprintf(logout,"Line %d: statement : WHILE LPAREN expression RPAREN statement\n",line_count);
		$$ = new SymbolInfo("while(" + $3->getName() + ")" + $5->getName(),	"statement");
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		SymbolInfo* s = symbolTable.lookUp($3->getName());
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: Variable %s is not declared\n", line_count, $3->getName().c_str());
			fprintf(errorout, "Error at line %d: Variable %s is not declared\n", line_count, $3->getName().c_str());
		}

		fprintf(logout,"Line %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n",line_count);
		$$ = new SymbolInfo("printf(" + $3->getName() + ");", "statement");
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| RETURN expression SEMICOLON
	{
		if($2->getName() == "void") {
			errorCount++;
			fprintf(logout, "Error at line %d: Void function cannot have return statement\n", line_count);
			fprintf(errorout, "Error at line %d: Void function cannot have return statement\n", line_count);
		}
		fprintf(logout,"Line %d: statement : RETURN expression SEMICOLON\n",line_count);
		$$ = new SymbolInfo("return " + $2->getName() + ";", "statement");
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	  
expression_statement 	: SEMICOLON			
			{
				fprintf(logout,"Line %d: expression_statement : SEMICOLON\n",line_count);
				$$ = new SymbolInfo(";", "SEMICOLON");
				fprintf(logout, "%s\n", $$->getName().c_str());
			}
			| expression SEMICOLON 
			{
				fprintf(logout,"Line %d: expression_statement : expression SEMICOLON\n",line_count);
				$$ = new SymbolInfo($1->getName() + ";", "expression_statement");
				fprintf(logout, "%s\n", $$->getName().c_str());
			}
			;
	  
variable : ID 		
	{
		fprintf(logout,"Line %d: variable : ID\n",line_count);
		SymbolInfo* s = symbolTable.lookUp($1->getName());
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			fprintf(errorout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			$$ = new SymbolInfo($1->getName(), "error");
		}
		else {
			$$ = new SymbolInfo(s->getName(), s->getType());
			$$->setIdentity(s->getIdentity());
		}
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| ID LTHIRD expression RTHIRD 
	{
		fprintf(logout,"Line %d: variable : ID LTHIRD expression RTHIRD\n",line_count);
		SymbolInfo* s = symbolTable.lookUp($1->getName());
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			fprintf(errorout, "Error at line %d: Variable %s is not declared\n", line_count, $1->getName().c_str());
			$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]",	"error");
		}
		else {
			if(s->getIdentity() == "array") {
				if ($3->getType() != "int") {
					errorCount++;
					fprintf(logout, "Error at line %d: Array index must be integer\n", line_count);
					fprintf(errorout, "Error at line %d: Array index must be integer\n", line_count);
				}
				$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", s->getType());
			}
			else {
				errorCount++;
				fprintf(logout, "Error at line %d: Variable %s is not an array\n", line_count, $1->getName().c_str());
				fprintf(errorout, "Error at line %d: Variable %s is not an array\n", line_count, $1->getName().c_str());
				$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]",	"error");
			}
		}
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	 
expression : logic_expression	
	   {
			fprintf(logout,"Line %d: expression : logic_expression\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
			
			if(($1->getIdentity()!="variable") || ($3->getType()=="error") ) {
				errorCount++;
				fprintf(logout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
				fprintf(errorout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
			}
			else {
				if($1->getType() != $3->getType()) {
					cout << "yezz2 " << endl;
					if(($1->getType() == "float") && ($3->getType() == "int")) {}
					else {
						errorCount++;
						fprintf(logout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
						fprintf(errorout, "Error at line %d: Type mismatch between the operands of assignment operator\n", line_count);
					}	
				}
			}
			fprintf(logout,"Line %d: expression : variable ASSIGNOP logic_expression\n",line_count);
			$$ = new SymbolInfo($1->getName() + "=" + $3->getName(), "expression");
			fprintf(logout, "%s\n", $$->getName().c_str());
	   }
	   ;
			
logic_expression : rel_expression 	
		{
			fprintf(logout,"Line %d: logic_expression : rel_expression\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| rel_expression LOGICOP rel_expression 	
		{
			string retType = "error";
			if(($1->getType() != "int") || ($3->getType() != "int")) {
				errorCount++;
				fprintf(logout, "Error at line %d: operands of logical operator must be integer\n", line_count);
				fprintf(errorout, "Error at line %d: operands of logical operator must be integer\n", line_count);
			}
			else retType = "int";
			fprintf(logout,"Line %d: logic_expression : rel_expression LOGICOP rel_expression\n",line_count);
			$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), retType);
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
			
rel_expression	: simple_expression 
		{
			fprintf(logout,"Line %d: rel_expression	: simple_expression\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| simple_expression RELOP simple_expression	
		{
			fprintf(logout,"Line %d: rel_expression	: simple_expression RELOP simple_expression\n",line_count);
			$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(),	"int");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
				
simple_expression : term 
		{
			fprintf(logout,"Line %d: simple_expression : term\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| simple_expression ADDOP term 
		{
			fprintf(logout,"Line %d: simple_expression : simple_expression ADDOP term\n",line_count);
			if (($1->getType() == "float") || ($3->getType() == "float")) $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "float");
			else $$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "int");
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
					
term :	unary_expression
    {
		fprintf(logout,"Line %d: term : unary_expression\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	|  term MULOP unary_expression
    {
		string op = $2->getName();
		string retType = "error";

		if(op == "%") {
			if(($1->getType() != "int") || ($3->getType() != "int")) {
				errorCount++;
				fprintf(logout, "Error at line %d: operands of modulus operator must be integer\n", line_count);
				fprintf(errorout, "Error at line %d: operands of modulus operator must be integer\n", line_count);
			}
			else if($3->getName() == "0") {
				errorCount++;
				fprintf(logout, "Error at line %d: Modulus by zero\n", line_count);
				fprintf(errorout, "Error at line %d: Modulus by zero\n", line_count);
			}
			else retType = "int";
		}
		else if(op == "*" || op == "/") {
			if((op == "/") && ($3->getName() == "0")) {
				errorCount++;
				fprintf(logout, "Error at line %d: Division by zero\n", line_count);
				fprintf(errorout, "Error at line %d: Division by zero\n", line_count);
			}
			else {
				if(($1->getType() == "float") || ($3->getType() == "float")) retType = "float";
				else retType = "int";
			}
		}
		fprintf(logout,"Line %d: term : term MULOP unary_expression\n",line_count);
		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), retType);
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;

unary_expression : ADDOP unary_expression  
		{
			fprintf(logout,"Line %d: unary_expression : ADDOP unary_expression\n",line_count);
			$$ = new SymbolInfo($1->getName() + $2->getName(), $2->getType());
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| NOT unary_expression 
		{
			fprintf(logout,"Line %d: unary_expression : NOT unary_expression\n",line_count);
			$$ = new SymbolInfo("!" + $2->getName(), $2->getType());
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		| factor 
		{
			fprintf(logout,"Line %d: unary_expression : factor\n",line_count);
			$$ = $1;
			fprintf(logout, "%s\n", $$->getName().c_str());
		}
		;
	
factor	: variable 
	{
		fprintf(logout,"Line %d: factor : variable\n",line_count);
		$$ = $1;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| ID LPAREN argument_list RPAREN
	{
		SymbolInfo *s = symbolTable.lookUp($1->getName());
		if(s == nullptr) {
			errorCount++;
			fprintf(logout, "Error at line %d: function %s not declared or defined\n", line_count, $1->getName().c_str());
			fprintf(errorout, "Error at line %d: function %s not declared or defined\n", line_count, $1->getName().c_str());
		} else {
			if(s->getIdentity() == "function") {
				vector<string> argNames = splitString($3->getName(), ',');
				vector<string> argTypes = splitString($3->getType(), ',');
				vector<SymbolInfo*> sList = s->getParameterList();
				cout << "yez1 " << s->getParameterList()[0]->getType() << " " << s->getType() << endl;
				cout << "yez2 " << sList[0]->getName() << " " << sList[1]->getType() << endl;
				if(s->getType() == "void") {
					errorCount++;
					fprintf(logout, "Error at line %d: factor cannot be void function\n", line_count);
					fprintf(errorout, "Error at line %d: factor cannot be void function\n", line_count);
				}
				else if(sList.size() != argNames.size()) {
					errorCount++;
					fprintf(logout, "Error at line %d: Number of arguments do not match\n", line_count);
					fprintf(errorout, "Error at line %d: Number of arguments do not match\n", line_count);
				}
				else {
					for(int i=0; i<argNames.size(); i++) {
						if(argTypes[i] != sList[i]->getType()) {
							fprintf(errorout, "%s ...%s, %s ", argTypes[i].c_str(), sList[i]->getType().c_str(), sList[i]->getType().c_str());
							errorCount++;
							fprintf(logout, "Error at line %d: Argument types do not match\n", line_count);
							fprintf(errorout, "Error at line %d: Argument types do not match\n", line_count);
						}
					}
				}
			} else {
				errorCount++;
				fprintf(logout, "Error at line %d: ID is not function\n", line_count);
				fprintf(errorout, "Error at line %d: ID is not function\n", line_count);
			}
		}
		fprintf(logout,"Line %d: factor : variable\n",line_count);
		$$ = new SymbolInfo($1->getName() + "(" + $3->getName() + ")",	s->getType());
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| LPAREN expression RPAREN
	{
		fprintf(logout,"Line %d: factor : LPAREN expression RPAREN\n",line_count);
		$$ = new SymbolInfo("(" + $2->getName() + ")",	$2->getType());
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| CONST_INT 
	{
		fprintf(logout,"Line %d: factor : CONST_INT\n",line_count);
		$$ = yylval.var;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| CONST_FLOAT
	{
		fprintf(logout,"Line %d: factor : CONST_FLOAT\n",line_count);
		$$ = yylval.var;
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| variable INCOP 
	{
		fprintf(logout,"Line %d: factor : variable INCOP\n",line_count);
		$$ = new SymbolInfo($1->getName() + "++",	$1->getType());
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	| variable DECOP
	{
		fprintf(logout,"Line %d: factor : variable DECOP\n",line_count);
		$$ = new SymbolInfo($1->getName() + "--",	$1->getType());
		fprintf(logout, "%s\n", $$->getName().c_str());
	}
	;
	
argument_list : arguments
			  {
				fprintf(logout,"Line %d: argument_list : arguments\n",line_count);
				$$ = $1;
				fprintf(logout, "%s\n", $$->getName().c_str());
			  }
			  |
			  {
				fprintf(logout,"Line %d: arguments_list : \n",line_count);
				$$ = new SymbolInfo("", "void");
				fprintf(logout, "%s\n", $$->getName().c_str());
			  }
			  ;
	
arguments : arguments COMMA logic_expression
	      {
				fprintf(logout,"Line %d: arguments : arguments COMMA logic_expression\n",line_count);
				$$ = new SymbolInfo($1->getName() + "," + $3->getName(), $1->getType() + "," + $3->getType());
				fprintf(logout, "%s\n", $$->getName().c_str());
		  }
		  | logic_expression
	      {
				fprintf(logout,"Line %d: arguments : logic_expression\n",line_count);
				$$ = $1;
				fprintf(logout, "%s\n", $$->getName().c_str());
		  }
		  ;
 

%%
int main(int argc,char *argv[])
{

	cout << "start";
	if((fp = fopen(argv[1],"r")) == nullptr)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logout = fopen("log.txt", "w");
	errorout = fopen("error.txt", "w");
	
	cout << "start";

	yyin = fp;
	yyparse();
	

	fclose(logout);
	fclose(errorout);

	cout << "succes";
	
	return 0;
}

