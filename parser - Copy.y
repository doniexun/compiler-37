%{
#include <string.h>
#include <string>
#include <vector>
#include <iostream>
#include <algorithm>
#include <stack>
#include <stdio.h>
#include <stdlib.h>
#include "funkcje.h"
using namespace std;

typedef struct 
{
    string var;
    int val;
} Symbol;

// Kod wynikowy
vector<string> output;
int outputCounter = 0;

// Symbole
vector<Symbol> symbols;
int symbolCounter = 0;

// Tymczasowy stos
stack<int> tmpStack;

extern int yylineno;

void pushToOutput(string str);
void pushIntoRegister(string *num, int reg);
void pushIntoRegister(int num, int reg);
void fromMemoryToRegister(string *var, int reg);
void copyRegister(int i, int j);
void multiply();
void multiplyWithLoad(int tmp2);
void divide();


int yylex(void);
int getSymbolIndex(string *name);
int yyerror(const char *error) 
{ 
    printf("BLAD: Linia %d - %s", yylineno, error ); 
}
%}

%union	{
	std::string *num;
	std::string *str;
}

%token <str> ASSGNOP
%token <str> VAR
%token <str> START
%token <str> END
%token <str> IF
%token <str> THEN
%token <str> ELSE
%token <str> WHILE
%token <str> DO
%token <str> READ
%token <str> WRITE
%token <str> PLUS
%token <str> MINUS
%token <str> MUL
%token <str> DIV
%token <str> MOD
%token <str> EQ
%token <str> LEQ
%token <str> GEQ
%token <str> LT
%token <str> GT
%token <str> NEQ
%token <str> IDENTIFIER
%token <str> SEMICOLON
%token <str> NUMBER

%%
program : 	|
			VAR 
				vdeclarations
			START
				commands
			END 
			{
				pushToOutput("HALT");
			}

vdeclarations :	vdeclarations IDENTIFIER 
			{
				if(getSymbolIndex($<str>2) != -1)
				{
					cout << "ERROR linia " << yylineno << " : redeklaracja zmiennej " << $<str>2;
				}
				else
				{
					Symbol newSymbol = {*($<str>2), 0};
					symbols.push_back(newSymbol);
					symbolCounter++;
				}
			}
			|	;
				
commands : 	commands command 
			{
			
			}
			|	;

command :	IDENTIFIER ASSGNOP expression SEMICOLON
			{
				int tmp = getSymbolIndex($<str>1);
				if(tmp == -1)
				{
					cout << "ERROR linia " << yylineno << " : przypisanie do niezadeklarowanej zmiennej ";
				}
				else
				{
					pushToOutput("STORE 0 " + IntToString(tmp));
				}
			}
		|	IF condition THEN commands ELSE commands END 
			{
			}
		|	WHILE condition DO commands END
			{
			}
		|	READ IDENTIFIER SEMICOLON
			{
				int index = getSymbolIndex($<str>2);	    
				if (index != -1)
				{
					pushToOutput("SCAN " + IntToString(index));
				}
				else
				{
					cout << "ERROR Linia " << yylineno << " niezadeklarowana zmienna " << *$<str>2 << endl;
				}
			}
		|	WRITE value SEMICOLON
			{
				int index = getSymbolIndex($<str>2);	    
				if (index != -1)
				{
					pushToOutput("PRINT " + IntToString(index));
				}
				else
				{
					cout << "ERROR Linia " << yylineno << " niezadeklarowana zmienna " << *$<str>2 << endl;
				}
			}
		;
			
expression : value 
			{
				//Jesli value jest liczba
				if(czyLiczba($<str>1))
				{
					pushIntoRegister($<str>1, 0);		
				}
				//w przeciwnym wypadku wyciagamy z pamieci i wrzucamy do rejestru 0
				else
				{
					fromMemoryToRegister($<str>1, 0);
				}
			}
		|	value PLUS value 
		{
			//Przypadek nr 1: dwie liczby
			if(czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				pushIntoRegister($<str>1, 0);
				pushIntoRegister($<str>3, 1);
				pushToOutput("ADD 0 1");
			}
			
			//przypadek nr 2: liczba / zmienna
			else if(czyLiczba($<str>1) && !czyLiczba($<str>3))
			{
				pushIntoRegister($<str>1, 0);
				//ladujemy do rejestru 1 zmienna
				fromMemoryToRegister($<str>3, 1);
				pushToOutput("ADD 0 1");
			}
			
			else if(!czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				pushIntoRegister($<str>3, 0);
				//ladujemy do rejestru 1 zmienna
				fromMemoryToRegister($<str>1, 1);
				pushToOutput("ADD 0 1");
			}
			
			else
			{
				//ladujemy do dwoch rejestrow zmienne
				fromMemoryToRegister($<str>1, 0);
				fromMemoryToRegister($<str>3, 1);
				pushToOutput("ADD 0 1");
			}
		}
		|	value MINUS value 
		{
			//Przypadek nr 1: dwie liczby
			if(czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				pushIntoRegister($<str>1, 0);
				pushIntoRegister($<str>3, 1);
				pushToOutput("SUB 0 1");
			}
			
			//przypadek nr 2: liczba / zmienna
			else if(czyLiczba($<str>1) && !czyLiczba($<str>3))
			{
				pushIntoRegister($<str>1, 0);
				//ladujemy do rejestru 1 zmienna
				fromMemoryToRegister($<str>3, 1);
				pushToOutput("SUB 0 1");
			}
			
			else if(!czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				fromMemoryToRegister($<str>1, 0);
				pushIntoRegister($<str>3, 1);
				//ladujemy do rejestru 1 zmienna
				pushToOutput("SUB 0 1");
			}
			
			else
			{
				//ladujemy do dwoch rejestrow zmienne
				fromMemoryToRegister($<str>1, 0);
				fromMemoryToRegister($<str>3, 1);
				pushToOutput("SUB 0 1");
			}
		}
		|	value MUL value 
		{
			if(czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				int tmp1 = StringToInt($<str>1);
				int tmp2 = StringToInt($<str>3);
				if(tmp1 < tmp2) std::swap(tmp1, tmp2);
				pushIntoRegister(tmp1, 1);
				pushIntoRegister(tmp2, 2);
				multiply();
			}
			//przypadek nr 2: liczba / zmienna
			else if(czyLiczba($<str>1) && !czyLiczba($<str>3))
			{
				pushIntoRegister($<str>1, 1);
				fromMemoryToRegister($<str>3, 2);
				multiply();
			}
			else if(!czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				fromMemoryToRegister($<str>1, 1);
				pushIntoRegister($<str>3, 2);
				multiply();
			}
			
			else
			{
				//ladujemy do dwoch rejestrow zmienne
				fromMemoryToRegister($<str>1, 1);
				fromMemoryToRegister($<str>3, 2);
				multiply();
			}
		}
		|	value DIV value 
		{
			if(czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				int tmp1 = StringToInt($<str>1);
				int tmp2 = StringToInt($<str>3);
				pushIntoRegister(tmp1, 1);
				pushIntoRegister(tmp2, 2);
				divide();
			}
			//przypadek nr 2: liczba / zmienna
			else if(czyLiczba($<str>1) && !czyLiczba($<str>3))
			{
				pushIntoRegister($<str>1, 1);
				fromMemoryToRegister($<str>3, 2);
				divide();
			}
			else if(!czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				fromMemoryToRegister($<str>1, 1);
				pushIntoRegister($<str>3, 2);
				divide();
			}
			
			else
			{
				//ladujemy do dwoch rejestrow zmienne
				fromMemoryToRegister($<str>1, 1);
				fromMemoryToRegister($<str>3, 2);
				divide();
			}
		}
		|	value MOD value 
		{
			//modulo zasadniczo wykorzystuje algorytm dzielenia, reszta pojawia sie w R1
			if(czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				int tmp1 = StringToInt($<str>1);
				int tmp2 = StringToInt($<str>3);
				pushIntoRegister(tmp1, 1);
				pushIntoRegister(tmp2, 2);
				divide();
				pushToOutput("SUB 0 0");
				pushToOutput("ADD 0 1");
			}
			//przypadek nr 2: liczba / zmienna
			else if(czyLiczba($<str>1) && !czyLiczba($<str>3))
			{
				pushIntoRegister($<str>1, 1);
				fromMemoryToRegister($<str>3, 2);
				divide();
				
				pushToOutput("SUB 0 0");
				pushToOutput("ADD 0 1");
			}
			else if(!czyLiczba($<str>1) && czyLiczba($<str>3))
			{
				fromMemoryToRegister($<str>1, 1);
				pushIntoRegister($<str>3, 2);
				divide();
				
				pushToOutput("SUB 0 0");
				pushToOutput("ADD 0 1");
			}
			
			else
			{
				//ladujemy do dwoch rejestrow zmienne
				fromMemoryToRegister($<str>1, 1);
				fromMemoryToRegister($<str>3, 2);
				divide();
				
				pushToOutput("SUB 0 0");
				pushToOutput("ADD 0 1");
			}
		}
		;

condition : value EQ value {}
		|	value NEQ value {}
		|	value LT value {}
		|	value GT value {}
		|	value LEQ value {}
		|	value GEQ value {}
		;
		
value :		IDENTIFIER {}
		|	NUMBER {}
		;
%%

int main()
{ 
	yyparse();
	for(unsigned int i = 0; i < output.size(); ++i)
	{
		cout << output[i] << "\n";
	}
	//cout << "Program counter " << outputCounter<< endl;
	return 0;
}


int yyerror( char * str )
{
	printf( "BLAD: %s\n", str );
	exit(0);
}

void pushToOutput(string str)
{
	output.push_back(str);
	outputCounter++;
}

//MNOZNA: R1, MNOZNIK: R2
void multiply()
{
	pushToOutput("SUB 0 0");
	int currentCounter = outputCounter;
	//cout << "Curr COUNTER " << currentCounter << endl;
	pushToOutput("JZ 2 " + IntToString(outputCounter + 4));
	pushToOutput("ADD 0 1");
	pushToOutput("DEC 2");
	pushToOutput("JUMP " + IntToString(outputCounter - 3));
}

//DZIELNA: R1, DZIELNIK: R2, WYNIK: R0, reszta R1
void divide()
{
	pushToOutput("SUB 0 0");
	
	int current = outputCounter;
	//Jeœli w rejestrze R2 jest 0 skaczemy gdzies tam na koniec:
	pushToOutput("JZ 2 " + IntToString(outputCounter + 9));
	//Jeœli w rejestrze R1 jest 0, te¿ gdzieœ tam skaczemy na koniec
	pushToOutput("JZ 1 " + IntToString(outputCounter + 8));
	
	//w rejestrze 3 bedzie wynik R2 - R1 (dzielnik - dzielna)
	pushToOutput("SUB 3 3");
	pushToOutput("ADD 3 2");
	pushToOutput("SUB 3 1");
	
	//Jeœli dzielnik jest wiekszy od dzielnej, tzn R1 - R0 jest wieksze od 0
	pushToOutput("JG 3 " + IntToString(outputCounter + 4));
	pushToOutput("SUB 1 2"); //w przeciwnym wypadku odejmujemy dzielnik od dzielnej
	pushToOutput("INC 0"); //inkrementujemy wynik
	pushToOutput("JUMP " + IntToString(outputCounter - 7)); //skaczemy sobie do zupdateowania wartosci w R3
	
	//W R0 jest wynik, w R1 reszta
}

//mno¿y dwie liczby umieszczone w rejestrach R0 R1 uzywajac 2 i 3, tmp2 - liczba w postaci liczby
//ktora mozna zamienic na binarny
void multiplyWithLoad(int tmp2)
{	
	//Rozkladamy tmp2 na binarny
	int helper = tmp2;
	vector<bool> binary;
	while(helper > 0)
	{
		if(helper % 2 == 0)
		{
			binary.push_back(0);
			helper /= 2;
		}
		else
		{
			binary.push_back(1);
			helper /= 2;
		}
	}
	
	//niech najstarsze bity bêd¹ na koñcu
	//reverse(binary.begin(), binary.end());
	
	/*cout << "BINARNY DLA LICZBY " << tmp2 << endl;
	for(unsigned int i = 0; i < binary.size(); ++i)
	{
		 cout << binary[i];
	}
	cout << endl;
	*/
	//W rejestrze R0 - tmp1, w rejestrze R1 - tmp2
	//przenosimy R0 do R2, w R0 bedzie wynik
	pushToOutput("SUB 2 2");
	pushToOutput("ADD 2 0");
	pushToOutput("SUB 0 0");
	
	for(unsigned int i = 0; i < binary.size(); ++i)
	{
		if(binary[i] != 0)
		{
			//wrzucamy odpowiedni wykladnik do 3 rejestru
			pushIntoRegister(i, 3);
			//wrzucamy wartosc komorki 0 do 2
			//liczymy odpowiednia wartosc
			pushToOutput("SHL 2 3");
			//dodajemy ja do rejestru nr 0
			pushToOutput("ADD 0 2");
			//wykladnik w 3 rejestrze wracamy o odpowiednia wartosc
			pushToOutput("SHR 2 3");
		}
	}
}

int getSymbolIndex(string *name)
{
    for(unsigned int i = 0; i < symbols.size(); ++i)
    {
		if (symbols[i].var == *name)
			return i;
    }
    return -1;
}

//skopiuj j do i
void copyRegister(int i, int j)
{
	string ri = IntToString(i);
	string rj = IntToString(j);
	pushToOutput("SUB " + ri + " " + ri);
	pushToOutput("ADD " + ri + " " + rj);
}

void fromMemoryToRegister(string *var, int reg)
{
	int index = getSymbolIndex(var);
	if(index != -1)
	{
		pushToOutput("LOAD " + IntToString(reg) + " " + IntToString(index));
	}
	else
	{
		cout << "ERROR Linia " << yylineno << " niezadeklarowana zmienna " << *var << endl;				
	}
}

//dla rejestrow 0 - 3 -> w czwartym counter
void pushIntoRegister(int num, int reg)
{
	//zerujemy rejestry
	string tmp;
	string r = IntToString(reg);
	pushToOutput("SUB " + r + " " + r);
	pushToOutput("SUB 4 4");
	
	stack<string> s;	
	
	//w czworce wykladnik 2^1 (przesuwanie w lewo o 1 pozycje)
	pushToOutput("INC 4");
	
	while(num > 0)
	{
		tmp = "";
		if(num % 2 == 0)
		{	
			num /= 2;
			tmp += "SHL ";
			tmp += r;
			tmp += " 4";
			s.push(tmp);
		}
		else
		{
			num -= 1;
			tmp += "INC ";
			tmp += r;
			s.push(tmp);
		}
	}	
	
	while(!s.empty())
	{
		pushToOutput(s.top());
		s.pop();
	}
	
	//czyscimy rejestr 4 (counter)
	pushToOutput("SUB 4 4");
	
}

//dla rejestrow 0-3
void pushIntoRegister(string *num, int reg)
{
	//zerujemy rejestry
	string tmp;
	string r = IntToString(reg);
	pushToOutput("SUB " + r + " " + r);
	pushToOutput("SUB 4 4");
	
	stack<string> s;	
	
	//w czworce wykladnik 2^1 (przesuwanie w lewo o 1 pozycje)
	pushToOutput("INC 4");
	
	int value = atoi((*num).c_str());
	while(value > 0)
	{
		tmp = "";
		if(value % 2 == 0)
		{	
			value /= 2;
			tmp += "SHL ";
			tmp += r;
			tmp += " 4";
			s.push(tmp);
		}
		else
		{
			value -= 1;
			tmp += "INC ";
			tmp += r;
			s.push(tmp);
		}
	}	
	
	while(!s.empty())
	{
		pushToOutput(s.top());
		s.pop();
	}
}
