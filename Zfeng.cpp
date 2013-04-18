#include <cstdio>
#include <iterator>
#include <sstream>
#include <fstream>
#include <vector>
#include <cstdlib>
#include <algorithm>
#include <string>

using namespace std;

ofstream debug ("Zfeng.debug");
const int NUM_PREDICTORS = 5;
const bool DEBUG         = true;
const bool CONTEST       = false;
int stat[3]              = {0, 0, 0},
    total                = 0,
    counts[NUM_PREDICTORS * 2][3],
    turns[NUM_PREDICTORS * 2],
    shift[NUM_PREDICTORS * 2];
double expectation = 0.0,
       expectations[NUM_PREDICTORS * 2],
       rates[NUM_PREDICTORS * 2][3],
       predictions[NUM_PREDICTORS * 2][3];
string meaning[3] = {"Tie ", "Win ", "Lose"};
stringstream human, robot, result;

class Predictor{
public:
  Predictor(){};
  int total;
  virtual double* predict() = 0;
  virtual void getInput() = 0;
};

class UnigramPredictor : public Predictor{
public:
  UnigramPredictor(istream* is){
    in = is;
    total = 0;
  }
  
  double* predict(){
    getInput();
    return count;
  }
  
  void getInput(){
    char token;	
    token = in->get();
    in->putback(token);
    token -= '0';
    ++total;
    for(int i = 0; i < 3; i++)
      count[i] *= 0.9;
    count[token] += 1.0;
  }
  
private:
  istream* in;
  double count[3] = {0.0, 0.0, 0.0};
};

class BigramPredictor : public Predictor{
public:
  BigramPredictor(istream* is1, istream* is2){
    in1 = is1;
    in2 = is2;
    total = 0;
  }
	
  double* predict(){
    getInput();
    return count[last];
  }
  
  void getInput(){
    char token1, token2;
    
    token1 = in1->get();
    in1->putback(token1);
    token1 -= '0';
    
    token2 = in2->get();
    in2->putback(token2);
    token2 -= '0';

    for(int i = 0; i < 3; i++)
      for(int j = 0; j < 3; j++)
	count[i][j] *= 0.95;
    
    if(total > 0)
      count[last][token2] += 1.0;
    last = token1;
    ++total;
  }
  
private:
  int last;
  double count[3][3] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}};
  istream* in1;
  istream* in2;
};

class LongPatternMatcher : public Predictor{
public:
  LongPatternMatcher(istream* is){
    in = is;
    total = 0;
  }

  double* predict(){
    getInput();
    int patlen, last = history.back();
    double* ret = new double[3];
    ret[0] = 0; ret[1] = 0; ret[2] = 0;
    toDelete = ret;
    if(total < 5)
      return ret;
    for(int i = total - 2; i >= 0; i--){
      patlen = 0;
      for(int j = 3; j < 25 && history[i - j] == history[j]; j++)
	++patlen;
      ret[last] += patlen * patlen;
      last = history[i];
    }
    return ret;
  }
  
  void getInput(){
    if(toDelete != 0){
      delete[] toDelete;
    }
    char token;
    token = in->get();
    in->putback(token);
    token -= '0';
    history.push_back((unsigned short) token);
    ++total;
  }
	
private:
  istream* in;
  double* toDelete = 0x000000;
  vector<unsigned short> history;
};

Predictor* predictors[NUM_PREDICTORS] = {new UnigramPredictor(&human),
					 new BigramPredictor(&human, &human),
					 new BigramPredictor(&result, &human),
					 new BigramPredictor(&robot, &human),
					 new LongPatternMatcher(&human)};
Predictor* reflexive[NUM_PREDICTORS]  = {new UnigramPredictor(&robot),
					 new BigramPredictor(&robot, &robot),
					 new BigramPredictor(&result, &robot),
					 new BigramPredictor(&human, &robot),
					 new LongPatternMatcher(&robot)};

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
  return expectation > 0.0 && total > 2;
}

double* predict(){
  for(int i = 0; i < NUM_PREDICTORS; i++){
    double* t = predictors[i]->predict();
    for(int j = 0; j < 3; j++)
      predictions[i][(j + shift[i]) % 3] = t[j];
    if(DEBUG)
      debug << "Predictor " << i << " predicts ";
    copy(predictions[i], predictions[i] + 3, ostream_iterator<double>(debug, " "));
    debug << endl;
  }
  for(int i = 0; i < NUM_PREDICTORS; i++){
    double* t = reflexive[i]->predict();
    for(int j = 0; j < 3; j++)
      predictions[i + NUM_PREDICTORS][(j + shift[i + NUM_PREDICTORS]) % 3] = t[j];
    if(DEBUG)
      debug << "Predictor " << i + NUM_PREDICTORS << " predicts ";
    copy(predictions[i + NUM_PREDICTORS], predictions[i + NUM_PREDICTORS] + 3, ostream_iterator<double>(debug, " "));
    debug << endl;
  }
  int maxidx = distance(expectations, max_element(expectations,
						  expectations + 3));
  return predictions[maxidx];
}

int getRandom(){
  srand(time(NULL));
  return rand() % 3;
}

void putRandom(){
  switch(getRandom()){
  case 0:
    putchar('R');
    break;
  case 1:
    putchar('P');
    break;
  case 2:
    putchar('S');
    break;
  }
  if(CONTEST)
    fflush(stdout);
}

void verify(int h){
  for(int i = 0; i < NUM_PREDICTORS; i++)
    ++counts[i][(distance(predictions[i], max_element(predictions[i], predictions[i] + 3)) - h + 4) % 3];
  for(int i = 0; i < NUM_PREDICTORS; i++)
    ++counts[i + NUM_PREDICTORS][(distance(predictions[i + NUM_PREDICTORS],
					   max_element(predictions[i + NUM_PREDICTORS],
						       predictions[i + NUM_PREDICTORS] + 3))
				  - h + 4) % 3];
  for(int i = 0; i < NUM_PREDICTORS * 2; i++)
    for(int j = 0; j < 3; j++){
      rates[i][j] = 1.0 * counts[i][j] / total;
    }
  for(int i = 0; i < NUM_PREDICTORS * 2; i++){
    expectations[i] = rates[i][1] - rates[i][2];
    if(expectations[i] < 0.0)
      ++turns[i];
    if(turns[i] > 5){
      shift[i] += 2;
      turns[i] = 0;
    }
  }
  debug << "Expectations : ";
  copy(expectations, expectations + NUM_PREDICTORS * 2, ostream_iterator<double>(debug, " "));
  debug << endl;
}

int processPrediction(double* m){
  int r[3];
  for(int i = 0; i < 3; i++){
    int v = (m[i] > m[(i + 1) % 3]) + (m[i] > m[(i + 2) % 3]);
    if(v == 2)
      r[0] = i;
    else if(v == 1)
      r[1] = i;
    else
      r[2] = i;
  }
  if(m[r[0]] >= 1.5 * m[r[1]])
    return (r[0] + 4) % 3;
  else
    return ((r[0] - r[1] + 3) % 3 == 1 ? r[0] : r[1]);
}

void postPredict(int h, int b){
  switch(b){
  case 0:
    putchar('R');
    break;
  case 1:
    putchar('P');
    break;
  case 2:
    putchar('S');
    break;
  }
  if(CONTEST)
    fflush(stdout);
  if(!CONTEST)
    putchar('\n');
  human << h;
  robot << b;
  result << (h - b + 3) % 3;
  ++stat[(h - b + 3) % 3];
  ++total;
  expectation = 1.0 * stat[2] / total - 1.0 * stat[1] / total;
  if(!CONTEST)
    for(int i = 0; i < 3; i++)
      printf("%s %d %.2f\n", meaning[i].c_str(), stat[i], 1.0 * stat[i] / total);
}

int main(){
  char token;
  for(int i = 0; i < NUM_PREDICTORS; i++)
    for(int j = 0; j < 3; j++){
      counts[i][j] = 0;
      rates[i][j] = 0;
    }
  for(int i = 0; i < NUM_PREDICTORS; i++)
    shift[i + NUM_PREDICTORS] = 1;
  
  if(CONTEST)
    putRandom();
  
  while((token = getInput()) || true){
    debug << "Round " << total << ' ';
    if(predictOrRandom()){
      debug << endl;
      double* p = predict();
      verify(token);
      postPredict(token, processPrediction(p));
    }
    else{
      debug << ": Random fallback is in effect." << endl;
      if(total >= 2){
        predict();
	verify(token);
      }
      postPredict(token, getRandom());
      if(total == 0)
	for(int i = 0; i < NUM_PREDICTORS; i++){
	  predictors[i]->getInput();
	  reflexive[i]->getInput();
	}
    }
    if(total != 1){
      human.ignore();
      result.ignore();
      robot.ignore();
    }
  }
}
