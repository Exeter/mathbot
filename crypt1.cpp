/*
ID: wfan1
PROG: crypt1
LANG: C++
*/
#include <fstream>
#include <iostream>
#include <sstream>
#include <cstdio>
#include <string>
#include <cstring>
#include <vector>
#include <cmath>
#include <map>
#include <cctype>

using namespace std;

int n,count=0;
char arr[10];

string to_s(int i){
	ostringstream convert;
	convert << i;
	return convert.str();
}

int main(){
    ofstream fout ("crypt1.out");
    ifstream fin ("crypt1.in");
    fin >> n;
    for(int i=0;i<n;i++)
    	fin >> arr[i];
    for(int i=100;i<1000;i++)
    	for(int j=10;j<100;j++){
    		int p=i*(j%10);
    		if(p>999)
    			continue;
    		string s=to_s(p);
    		bool flag=false;
    		for(int m=0;i<s.length();m++){
    			flag=false;
    			for(int q=0;q<n;q++)
    				if(s[m]==arr[q])
    					flag=true;
    			if(!flag)
    				break;
    		}
    		if(!flag)
    			continue;
    		p=i*(j/10);
    		if(p>999)
    			continue;
    		s=to_s(p);
    		flag=false;
    		for(int m=0;i<s.length();m++){
    			flag=false;
    			for(int q=0;q<n;q++)
    				if(s[m]==arr[q])
    					flag=true;
    			if(!flag)
    				break;
    		}
    		if(!flag)
    			continue;
    		p=i*j;
    		if(p>9999)
    			continue;
    		flag=false;
    		for(int m=0;i<s.length();m++){
    			flag=false;
    			for(int q=0;q<n;q++)
    				if(s[m]==arr[q])
    					flag=true;
    			if(!flag)
    				break;
    		}
    		if(!flag)
    			continue;
    		count++;
    	}
    fout << count << endl;
    return 0;
}
