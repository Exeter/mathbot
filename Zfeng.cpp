#include <cstdio>
#include <sstream>
#include <fstream>
#include <vector>
#include <cstdlib>
#include <algorithm>
#include <string>

using namespace std;

const int NUM_PREDICTORS = 6;
int stat[3] = {0, 0, 0}, total = 0, predictions[NUM_PREDICTORS][3];
double expectation = 0.0, expectations[NUM_PREDICTORS];
stringstream human, robot, result;

class Predictor{
	public:
		int total = 0;
		virtual int* predict();
	private:
		int stats[3] = {0, 0, 0};
};

class UnigramPredictor : public Predictor{
	public:
		UnigramPredictor(istream* is){
			in = is;
			total = 0;
			}

			int* predict(){
			getInput();
			int* ret = count;
			for(int i = 0; i < 3; i++)
				ret[i] /= 1.0 * total;
			return ret;
		}

	private:
		istream * in;
		int count[3] = {0, 0, 0};
		void getInput(){
			char token;
			if(in->peek() == EOF)
				in->unget();	
			token = in->get() - '0';
			++count[token];
		}
};

class BigramPredictor : public Predictor{
	public:
		BigramPredictor(istream* is1, istream* is2){
	    		in1 = is1;
	    		in2 = is2;
	    		total = 0;
		}
	
		int* predict(){
			getInput();
			int* ret = count[last];
			for(int i = 0; i < 3; i++)
				ret[i] /= 1.0 * total;
			return ret;
		}
	private:
		int last, count[3][3] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}};
		istream * in1;
		istream * in2;
		void getInput(){
			char token1, token2;
			if(in1->peek() == EOF)
	        	in1->unget();
			if(in2->peek() == EOF)
				in2->unget();
			token1 = in1->get();
			token2 = in2->get();
			++count[last][token2-'0'];
			last = token1;
		}
};

Predictor* predictors[NUM_PREDICTORS] = {new UnigramPredictor(&human), new BigramPredictor(&human, &human), new BigramPredictor(&result, &human), new BigramPredictor(&robot, &human), new LongPatternMatcher(&human)};
Predictor* reflexive[NUM_PREDICTORS] = {new UnigramPredictor(&robot), new BigramPredictor(&robot, &robot), new BigramPredictor(&result, &robot), new BigramPredictor(&human, &robot), new LongPatternMatcher(&robot)};

int getInput(){
	start:
	char c = getchar();
	if(c != EOF)
		switch(c){
			case 'R':
				return 0;
			case 'P':
				return 1;
			case 'S':
				return 2;
			default:
				goto start;
		}
	else
		exit(0);
}

bool predictOrRandom(){
	return expectation > 0.0 && total >= 2;
}

int predict(){
	for(int i = 0; i < NUM_PREDICTORS; i++){
		int* t = predictors[i]->predict();
		for(int j = 0; j < 3; j++)
			predictions[i][j] = t[j];
	}
	int idx = 0, val = 0;
	for(int i = 0; i < NUM_PREDICTORS; i++)
		if(expectations[i] > val){
			val = expectations[i];
			idx = i;
		}
	
}

int getRandom(){
	return rand() % 3;
}

void verify(int m){
	/*
	for(int i = 0; i < NUM_PREDICTORS; i++){
		switch(distance(predictions[i], max_element(predictions[i], predictions[i] + 3))){
			case 0:
				predictors[i].rate
		}
	*/
}

int processPrediction(int m){
}

void postPredict(int h, int b){
	switch(b){
		case 0:
			putchar('R');
		case 1:
			putchar('P');
		case 2:
			putchar('S');
	}
	human << h;
	robot << b;
	result << (h - b + 3) % 3;
	++stat[(h - b + 3) % 3];
	++total;
	for(int i = 0; i < 3; i++)
		printf("%d %f\n", stat[i], 1.0 * stat[i] / total);
}

int main(){
	char token;
	while((token = getInput()))
		if(predictOrRandom()){
			int p = predict();
			verify(token, p);
			postPredict(token, processPrediction(p));
		}
		else
			postPredict(token, getRandom());
	
}
