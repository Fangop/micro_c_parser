/*	Definition section */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


struct SYMBOL{
    char *name;
    char *entryType;
    char *dataType;
    int scope;
    char *parameter;
};

struct ERROR_SET{
    int flag;
    char msg[256];
};


typedef struct SYMBOL symbol;
typedef struct ERROR_SET error;
struct NODE{
    symbol* s;
    struct NODE* next;
};
typedef struct NODE node;
node* list_head;
error err;
int Scope = 0;

void yyerror(char *s);

extern int yylineno;
extern int yylex();
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex

/* Symbol table function - you can add new function if needed. */
int lookup_symbol(char*,int);
int lookup_symbol_visible_scope(char*);
node* create_symbol(char*, char*,char* ,char*);
void insert_symbol(node*);
void dump_symbol(int);
void print_symbol(int,node*);
node* remove_node(node*);
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int boolean;
    int i_val;
    double f_val;
    char* string;
}

/* Token without return */
%token PRINT
%token IF ELSE WHILE RETURN

%token GE_OP LE_OP EQ_OP NE_OP AND_OP OR_OP
%token INC_OP DEC_OP

%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN

%token <string> VOID INT FLOAT STRING BOOL

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> STRING_LITERAL ID
%token <boolean> TRUE FALSE


/* Nonterminal with return, which need to sepcify type */
%type <string> variable_declaration function_definition parameter_list parameter_declarator type_specifier

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */

%%
program
    : external_declaration 
    | program external_declaration
;

external_declaration
    : variable_declaration
    | function_definition compound_statement 
;

variable_declaration
    : type_specifier ID ';' {
        if(!lookup_symbol($2,Scope))
            create_symbol($2, "variable", $1, "");
        else{
            err.flag = 1;
            sprintf(err.msg,"Redeclared variable %s",$2);
        }
        }
    | type_specifier ID '=' assignment_expression ';' {
        if(!lookup_symbol($2,Scope))
            create_symbol($2, "variable", $1, "");
        else{
            err.flag = 1;
            sprintf(err.msg,"Redeclared variable %s",$2);
        }
    }
;

function_definition
    : type_specifier ID '(' ')'                 {create_symbol($2,"function",$1,"");}
    | type_specifier ID '(' parameter_list ')'  {create_symbol($2,"function",$1,$4);}
;

type_specifier
	: VOID   { $$ = $1; }
	| INT    { $$ = $1; }
	| FLOAT  { $$ = $1; }
	| STRING { $$ = $1; }
	| BOOL   { $$ = $1; }
;

assignment_expression
    : unary_expression assignment_operator assignment_expression
    | conditional_expression
; 
unary_expression
	:postfix_expression
	|INC_OP unary_expression
	|DEC_OP unary_expression
	|unary_operator unary_expression
;

postfix_expression
    :primary_expression
    |ID '(' ')' {
        if(!lookup_symbol_visible_scope( $1)){
            err.flag =1;
            sprintf(err.msg, "Undeclared function %s", $1);
        }
    }
    |ID '(' argument_expression_list ')' {
        if(!lookup_symbol_visible_scope($1)){
            err.flag =1 ;
            sprintf(err.msg, "Undeclared function %s", $1);
        }
    }
	|postfix_expression INC_OP 
	|postfix_expression DEC_OP
;

primary_expression
	:ID	{
    if(!lookup_symbol_visible_scope($1)){
        err.flag = 1;
        sprintf(err.msg, "Undeclared variable %s", $1);
    }
    }
	|constant
	|'(' expression ')'
;

constant
	:I_CONST
	|F_CONST
	|TRUE
	|FALSE
	|STRING_LITERAL
;

expression
	:assignment_expression
	|expression ',' assignment_expression
;

parameter_list
    : parameter_declarator { $$ = $1; }
    | parameter_list ',' parameter_declarator { sprintf($$ ,"%s, %s",$1,$3);}
;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
;

unary_operator
	:'+'
	|'-'
	|'!'
;

assignment_operator
	:'='
	|ADD_ASSIGN
	|SUB_ASSIGN
	|MUL_ASSIGN	
	|DIV_ASSIGN	
	|MOD_ASSIGN

;

parameter_declarator
    :type_specifier  ID {Scope++; create_symbol($2,"parameter",$1,"");Scope--;}
;
conditional_expression
	:logical_or_expression
	|logical_or_expression '?' expression ':' conditional_expression
;

logical_or_expression
	:logical_and_expression
	|logical_or_expression OR_OP logical_and_expression
;

logical_and_expression
	:equality_expression
	|logical_and_expression AND_OP equality_expression
;

equality_expression
	:relational_expression
	|equality_expression EQ_OP relational_expression
	|equality_expression NE_OP relational_expression
;

relational_expression
	:additive_expression
	|relational_expression '<' additive_expression
	|relational_expression '>' additive_expression
	|relational_expression LE_OP additive_expression
	|relational_expression GE_OP additive_expression
;

additive_expression
	:multiplicative_expression
    |additive_expression '+' multiplicative_expression
    |additive_expression '-' multiplicative_expression
;

multiplicative_expression
	:unary_expression
	|multiplicative_expression '*' unary_expression
	|multiplicative_expression '/' unary_expression
	|multiplicative_expression '%' unary_expression
;

statement
	:compound_statement
	|expression_statement
	|selection_statement
    |iteration_statement
    |jump_statement
	|print_statement
;

expression_statement
	:';'
	|expression ';'
;

selection_statement
    :IF '(' expression ')' statement ELSE statement
;

iteration_statement
	:WHILE '('expression')' statement
	;

jump_statement
	:RETURN ';'
	|RETURN expression ';'
	;

print_statement
	:PRINT '(' ID ')' ';' {
        if(!lookup_symbol_visible_scope($3)){
            err.flag = 1;
            sprintf(err.msg, "Undeclared variable %s", $3);
        }
    }
	|PRINT '(' STRING_LITERAL ')' ';'
	;

compound_statement
	:'{' '}'
	|'{'  block_item_list '}' 
;

block_item_list
	:block_item
	|block_item_list block_item
;

block_item
	:variable_declaration
    |statement
;

%%

/* C code section */
int main(int argc, char** argv)
{
    
    yylineno = 0;
    err.flag = 0;
    list_head = malloc(sizeof(node));
    list_head->next = NULL;
    yyparse();

    return 0;
}


void yyerror(char *s)
{
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
return;
}

node* create_symbol(char* _n,char* _e, char* _d, char* _p) {
    node* new_node;
    //printf("%s %s %s %d %s\n",_n, _e,_d,Scope,_p);
    new_node = malloc(sizeof(node));
    new_node->s = malloc(sizeof(symbol));
    new_node->s->name = strdup(_n);
    new_node->s->entryType = strdup(_e);
    new_node->s->dataType = strdup(_d);
    new_node->s->parameter = strdup(_p);
    new_node->s->scope = Scope;
    insert_symbol(new_node);
    return new_node;
}
void insert_symbol(node* new_node) {
    node* tmp = list_head;
    while(tmp->next!= NULL)
        tmp = tmp->next;
    tmp->next = new_node;
    new_node->next = NULL;
}
node* remove_symbol(node* remove_node){
    node* prev = list_head;
    while(prev->next != remove_node)
        prev = prev->next;
    prev->next = remove_node->next;
    free(remove_node);
    return prev->next;
}
int lookup_symbol_visible_scope(char*n) {
    node* now = list_head;
    int i = 0;
    now = now->next;
    while(now!= NULL){
        if(strcmp(now->s->name, n) == 0)
            if(now->s->scope <= Scope)
                return 1;
        now = now->next;
    }
    return 0;
}
int lookup_symbol(char*  n,int s) {
    node* now = list_head;
    int i = 0;
    now = now->next;
    while(now!= NULL){
        if(strcmp(now->s->name, n) == 0)
            if(now->s->scope == s)
                return 1;
        now = now->next;
    }
    return 0;
}
void dump_symbol(int scope) {
    node* now = list_head;
    int i = 0;
    now = now->next;
    while(now!= NULL){
        if(now->s->scope == Scope)
            i++;
        now = now->next;
    }
    if(i>0)
        printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n","Index", "Name", "Kind", "Type", "Scope", "Attribute");
    now = list_head;
    i = 0;
    now = now->next;
    while(now != NULL){
        if(now ->s-> scope == scope){
        print_symbol(i,now);
        now = remove_symbol(now);
        i++;
        }else{
        now = now->next;
        }
    }
    if(i>0)
        printf("\n");
}
void print_symbol(int i,node* now){
    printf("%-10d%-10s%-12s%-10s%-10d%-10s\n",i,now->s->name,now->s->entryType,now->s->dataType,now->s->scope,now->s->parameter);
}