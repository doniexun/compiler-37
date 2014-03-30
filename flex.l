%option yylineno

%{
	#include <string.h>
	#include <string>
	#include <stdlib.h>
	#include "parser.tab.h"
	
	int yylex();
%}
%x comment

%%
"(*"					BEGIN(comment);
<comment>[^*\n]*        ;
<comment>"*"+[^*)\n]*   ;
<comment>\n             ;
<comment>"*"+")"        BEGIN(INITIAL);

[ \t\r\n]+	{}
VAR			{ return(VAR); }
BEGIN		{ return(START); }
END			{ return(END); }
":="		{ return(ASSGNOP); }
WHILE		{ return(WHILE); }
DO			{ return(DO); }
IF			{ return(IF); }
THEN		{ return(THEN); }
ELSE		{ return(ELSE); }
WRITE		{ return(WRITE); }
READ		{ return(READ); }
"=="		{ return(EQ); } 
"<"			{ return(LT); }
">"			{ return(GT); }
"<="		{ return(LEQ); }
">="		{ return(GEQ); }
"!="		{ return(NEQ); }
"+"			{ return(PLUS); }
"-"			{ return(MINUS); }
"*"			{ return(MUL); }
"/"			{ return(DIV); }
"%"			{ return(MOD); }
[0-9]+		{    
				yylval.num = new std::string(yytext);
				return(NUMBER);
			}
[_a-z]+		{ 
				yylval.str = new std::string(yytext);
				return(IDENTIFIER);  
			}
";"			{ return(SEMICOLON); }
.			;
%%

int yywrap(void) {}