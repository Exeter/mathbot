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
bool CONTEST             = false;
int stat[3]              = {0, 0, 0},
    total                = 0,
    h,
    turns[NUM_PREDICTORS * 2],
    shift[NUM_PREDICTORS * 2];
long double expectation = 0.0,
       expectations[NUM_PREDICTORS * 2],
       rates       [NUM_PREDICTORS * 2][3],
       predictions [NUM_PREDICTORS * 2][3],
       counts      [NUM_PREDICTORS * 2][3];
string meaning[3] = {"Tie ", "Win ", "Lose"};
stringstream human, robot, result;

class Predictor{
public:
  Predictor(){};
  int total;
  virtual long double* predict() = 0;
  virtual void getInput() = 0;
};

class UnigramPredictor : public Predictor{
public:
  UnigramPredictor(istream* is){
    in = is;
    total = 0;
  }
  
  long double* predict(){
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
      count[i] *= 0.87358;
    count[token] += 1.0;
  }
  
private:
  istream* in;
  long double count[3] = {0.0, 0.0, 0.0};
};

class BigramPredictor : public Predictor{
public:
  BigramPredictor(istream* is1, istream* is2){
    in1 = is1;
    in2 = is2;
    total = 0;
  }
	
  long double* predict(){
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
	count[i][j] *= 0.9;
    
    if(total > 0)
      count[last][token2] += 1.0;
    last = token1;
    ++total;
  }
  
private:
  int last;
  long double count[3][3] = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}};
  istream* in1;
  istream* in2;
};

class LongPatternMatcher : public Predictor{
public:
  LongPatternMatcher(istream* is){
    in = is;
    total = 0;
  }

  long double* predict(){
    getInput();
    int last = history.back();
    long double* ret = new long double[3];
    ret[0] = 0; ret[1] = 0; ret[2] = 0;
    toDelete = ret;
    if(total < 5)
      return ret;
    for(int i = total - 2; i >= 0; i--){
      for(int x = 0; history[i - x] == history[total - 1 - x] && x < 25; x++)
        ret[last] += x;
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
    history.push_back((unsigned char) token);
    ++total;
  }
	
private:
  istream* in;
  long double* toDelete = 0x000000;
  vector<unsigned char> history;
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
  return *max_element(expectations, expectations + 2 * NUM_PREDICTORS) > 0.0 && total > 2;
}

long double* predict(){
  for(int i = 0; i < NUM_PREDICTORS; i++){
    long double* t = predictors[i]->predict();
    for(int j = 0; j < 3; j++)
      predictions[i][(j + shift[i]) % 3] = t[j];
    debug << "Predictor " << i << " predicts ";
    copy(predictions[i], predictions[i] + 3, ostream_iterator<long double>(debug, " "));
    debug << endl;
  }
  for(int i = 0; i < NUM_PREDICTORS; i++){
    long double* t = reflexive[i]->predict();
    for(int j = 0; j < 3; j++)
      predictions[i + NUM_PREDICTORS][(j + shift[i + NUM_PREDICTORS]) % 3] = t[j];
    if(DEBUG)
      debug << "Predictor " << i + NUM_PREDICTORS << " predicts ";
    copy(predictions[i + NUM_PREDICTORS], predictions[i + NUM_PREDICTORS] + 3, ostream_iterator<long double>(debug, " "));
    debug << endl;
  }
  int maxidx;
  for(int i = 0; i < NUM_PREDICTORS * 2; i++){
    int rank = 0;
    for(int j = 1; j < NUM_PREDICTORS * 2; j++)
      rank += (expectations[i] >= expectations[(i + j) % (2 * NUM_PREDICTORS)]);
    if(rank == 2 * NUM_PREDICTORS - 1){
      maxidx = i;
      break;
    }
  }
  debug << "Adopting predictor " << maxidx << endl;
  return predictions[maxidx];
}

int getRandom(){
  return rand() % 3;
}

void verify(int h){
  for(int i = 0; i < NUM_PREDICTORS; i++){
    counts[i][(distance(predictions[i], max_element(predictions[i], predictions[i] + 3)) - h + 4) % 3] *= 0.99;
    counts[i][(distance(predictions[i], max_element(predictions[i], predictions[i] + 3)) - h + 4) % 3] += 1.0;
  }
  for(int i = 0; i < NUM_PREDICTORS; i++){
    counts[i + NUM_PREDICTORS][(distance(predictions[i + NUM_PREDICTORS],
					   max_element(predictions[i + NUM_PREDICTORS],
						       predictions[i + NUM_PREDICTORS] + 3))
				  - h + 4) % 3] *= 0.99;
    counts[i + NUM_PREDICTORS][(distance(predictions[i + NUM_PREDICTORS],
					   max_element(predictions[i + NUM_PREDICTORS],
						       predictions[i + NUM_PREDICTORS] + 3))
				  - h + 4) % 3] += 1.0;
  }
  for(int i = 0; i < NUM_PREDICTORS * 2; i++){
    long double sum = 0.0;
    for(int j = 0; j < 3; j++)
      sum += counts[i][j];
    for(int j = 0; j < 3; j++)
      rates[i][j] = 1.0 * counts[i][j] / sum;
  }
  for(int i = 0; i < NUM_PREDICTORS * 2; i++){
    expectations[i] = rates[i][1] - rates[i][2];
    if(expectations[i] < 0.0)
      ++turns[i];
    if(turns[i] > 3){
      shift[i] += 2;
      turns[i] = 0;
    }
  }
  debug << "Shift ";
  copy(shift, shift + 2 * NUM_PREDICTORS, ostream_iterator<int>(debug, " "));
    debug << endl;
  debug << "Expectations : ";
  copy(expectations, expectations + NUM_PREDICTORS * 2, ostream_iterator<long double>(debug, " "));
  debug << endl;
}

int processPrediction(long double* m){
  long double rock_expectation = m[2] - m[1];
  long double paper_expectation = m[0] - m[2];
  long double scissor_expectation = m[1] - m[0];
  if (rock_expectation > scissor_expectation && rock_expectation > paper_expectation)
    return 0;
  else if(paper_expectation > rock_expectation && paper_expectation > scissor_expectation)
    return 1;
  else
    return 2;
}

void postPredict(int b){
  if(!CONTEST)
    h = getInput();
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
  if(CONTEST){
    fflush(stdout);
    h = getInput();
    debug << "Opponent plays " << h << ", and I play " << b << endl;
  }
  if(!CONTEST){
    putchar('\n');
  }
  human << h;
  robot << b;
  result << (h - b + 3) % 3;
  ++stat[(h - b + 3) % 3];
  ++total;
  expectation = 1.0 * stat[2] / total - 1.0 * stat[1] / total;
  debug << "Overall expectation : " << expectation << endl;
  if(!CONTEST)
    for(int i = 0; i < 3; i++)
      printf("%s %d %.2f\n", meaning[i].c_str(), stat[i], 1.0 * stat[i] / total);
}

int main(int argc, char* argv[]){
  CONTEST = atoi(argv[1]);
  char token;
  for(int i = 0; i < NUM_PREDICTORS; i++)
    for(int j = 0; j < 3; j++){
      counts[i][j] = 0;
      rates[i][j] = 0;
    }
  for(int i = 0; i < NUM_PREDICTORS; i++)
    shift[i + NUM_PREDICTORS] = 1;
  
  while(true){
    debug << "Round " << total + 1 << ' ';
    if(predictOrRandom()){
      debug << endl;
      long double* p = predict();
      postPredict(processPrediction(p));
      verify(h);
    }
    else{
      debug << ": Random fallback is in effect." << endl;
      if(total >= 2){
        predict();
      }
      postPredict(getRandom());
      verify(h);
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
