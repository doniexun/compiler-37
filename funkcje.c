#include "funkcje.h"
#include <sstream>
#include <string>
using namespace std;
bool czyLiczba(string *str)
{
	//jesli jest cyfra na pozycji 0 -> true
	if((*(str))[0] >= 48 && (*(str))[0] <= 57) return true;
	return false;
}

string IntToString(long long  i)
{
	stringstream ss;
	ss << i;
	return string(ss.str());
}

long long int StringToInt(string *str)
{
	long long  i;
	istringstream iss(*str);
	iss >> i;
	return i;
}