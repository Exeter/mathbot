#!/usr/bin/ruby
$overturn_threshold=-0.67448/6

class Zfeng

  def initialize()
    @current=0
    @count=[0,0,0]
    @actualcount=[0,0,0]
    @predictors=[Unigram_predictor.new,Bigram_predictor.new,Result_predictor.new,Response_predictor.new,Self_bigram_predictor.new,LongPatternMatcher.new,SelfPatternMatcher.new]
    @prediction=[]
    @total=0
    @rate=[0,0,0]
    @expectation=0
    @debug=File.new("Zfeng.debug","w")
    @flip=0
    @lastflip=0
    @record=[]
    @magicnumber=0.99
  end

 # Main method
  def start
    while(true)
      move=predict
      post_predict(move)
    end
  end

  # Get input from console
  def getInput
    input=STDIN.gets.chomp
    case input
      when "R"
        @current=1
      when "P"
        @current=2
      when "S"
        @current=3
    end
    feed_all(@current,1)
  end

  def getRandom
    return (Random.rand*3).floor+1
  end

  def assimilate
    for i in 0...@predictors.size
      @prediction[i]=@predictors[i].predict
    end
    @debug.write("Unigram predictor predicts " + @prediction[0].to_s+"\n")
    @debug.write("Result predictor predicts " + @prediction[2].to_s + "\n")
    @debug.write("Bigram predictor predicts " + @prediction[1].to_s + "\n")
    @debug.write("Response predictor predicts " + @prediction[3].to_s + "\n")
    @debug.write("Self-Markov predictor predicts " + @prediction[4].to_s + "\n")
    @debug.write("Long Pattern matcher predicts " + @prediction[5].to_s + "\n")
    @debug.write("Self Pattern matcher predicts " + @prediction[6].to_s + "\n")
    result=[0,0,0]
    expectations=[0,0,0,0,0,0]
    for i in 1...@predictors.size-2
      expectations[i]=@predictors[i].expectation
      expectations[i]=-1 if @prediction[i]==nil
    end
    result=@prediction[expectations.index(expectations.max)]
    @debug.write("Adopting predictor "+expectations.index(expectations.max).to_s+"\n")
    @debug.write("Aggregate is betting on " + result.to_s + "\n")
    first=result.index(result.max)
    second=result.index(result.sort[-2])
    if (first-second+3)%3==1
      final=first+1
    else
      final=second+1
    end
    if result[second]<0.0||result[first]-result[second]>=0.5*result[second]
      final=(first+1)%3==0?3:(first+1)%3
    end
    if @prediction[6]!=[0,0,0]&&@prediction[6]!=nil
      final=((@prediction[6].index(@prediction[6].max)+2)%3==0?3:(@prediction[6].index(@prediction[6].max)+2)%3)
    end
    if @prediction[5]!=[0,0,0]&&@prediction[5]!=nil
      final=((@prediction[5].index(@prediction[5].max)+2)%3==0?3:(@prediction[5].index(@prediction[5].max)+2)%3)
    end
    if expectations.max<=0.15
        final=getRandom
        @debug.write("Random fallback in effect\n")
    end
    return final
  end

  def predict
    move=0
    if @total==0
      move=getRandom
    else
      move=assimilate
    end
    return move
  end

  def post_predict(move)
    @total+=1
    getInput
    case move
      when 1
        print "R"
      when 2
        print "P"
      when 3
        print "S"
    end
    print "\n"
    feed_all(move,2)
    result=(move-@current+3)%3
    for i in 0...3
      @count[i]*=@magicnumber
    end
    case result
      when 1
        @count[0]+=1
        @actualcount[0]+=1
        feed_all(1,3)
        print("You lost!" )
      when 2
        @count[1]+=1
        @actualcount[1]+=1
        feed_all(-1,3)
        print("You won!" )
      when 0
        @count[2]+=1
        @actualcount[2]+=1
        feed_all(0,3)
        print("You tied!" )
    end
    print("\n" )
    flip
    expectations=[]
    for i in 0...@predictors.size
      expectations[i]=@predictors[i].expectation
    end
    @debug.write("Expectations >> "+expectations.to_s+"\n")
    @debug.write("Aggregate expectation >> "+@expectation.to_s+"\n")
    print("Scores:" + "\n")
    print("Computer Win:" + @actualcount[0].to_s + " Percentage:"+(@actualcount[0].to_f/(@actualcount[0]+@actualcount[1]+@actualcount[2])).to_s+ "\n")
    print("Tie:"  + @actualcount[2].to_s + " Percentage:"+(@actualcount[2].to_f/(@actualcount[0]+@actualcount[1]+@actualcount[2])).to_s+ "\n")
    print("Computer Lost:"  + @actualcount[1].to_s + " Percentage:"+(@actualcount[1].to_f/(@actualcount[0]+@actualcount[1]+@actualcount[2])).to_s+ "\n")\
  end

  def flip
    for i in 0...@predictors.size
      @predictors[i].flip
    end
  end
  
  def feed_all(move,type)
    for i in 0...@predictors.size
      @predictors[i].feed(move,type)
    end
  end 
end

class Predictor
  
  attr_accessor :history, :self, :result, :flip, :lastflip, :prediction, :magicnumber, :expectation, :name
  def initialize()
    @history=[]
    @self=[]
    @result=[]
    @flip=0
    @lastflip=0
    @prediction=[0,0,0]
    @rate=[0.0,0.0,0.0]
    @count=[0,0,0]
    @expectation=1.0
  end
  
  # Feed the data to the predictor
  # 1. Human 2. Bot 3. Result
  def feed(move,type)
    case type
    when 1
      @history.push(move)
      if @prediction.max!=0
        for i in 0...3
          @rate[i]*=0.9
        end
        case ((move-(@prediction.index(@prediction.max)+1))+3)%3
        when 0
          @rate[0]+=1
        when 1
          @rate[1]+=1
        when 2
          @rate[2]+=1
        end
        @expectation*=0.1
        @expectation+=0.9*(@rate[0]/(@rate[0]+@rate[1]+@rate[2])-@rate[2]/(@rate[0]+@rate[1]+@rate[2]))
      end
    when 2
      @self.push(move)
    when 3
      @result.push(move)
    end
  end
  
  def flip
    return if (@rate[0] - @rate[2] > @rate[1] - @rate[0] && @rate[0] - @rate[2] > @rate[2] - @rate[1])
    if @rate[1] - @rate[0] > @rate[2] - @rate[1]
      t = @rate[0]
      @rate[0] = @rate[1]
      @rate[1] = @rate[2]
      @rate[2] = t
      @flip+=2
    else
      t = @rate[2];
      @rate[2] = @rate[1];
      @rate[1] = @rate[0];
      @rate[0] = t;
      @flip+=1
    end
  end
end

class Unigram_predictor < Predictor
  
  def initialize
    super
    @humancount=[0.0,0.0,0.0]
    @magicnumber=0.5
  end
  
  def feed(move,type)
    super(move,type)
    return if type!=1
    for i in 0...@humancount.size
      @humancount[i]*=@magicnumber
    end
    @humancount[move-1]+=1.0
  end
  
  def predict
    total=@humancount[0]+@humancount[1]+@humancount[2]
    ret=[@humancount[0]/total,@humancount[1]/total,@humancount[2]/total]
    ret[0],ret[1],ret[2]=ret[(@flip)%3],ret[(1+@flip)%3],ret[(2+@flip)%3]
    @prediction=ret
    return ret
  end
end

class Bigram_predictor < Predictor
  
  def initialize
    super
    @bigrams=[[0,0,0],[0,0,0],[0,0,0]]
    @magicnumber=0.96
  end
  
  def feed(move,type)
    super(move,type)
    if type==1
      for i in 0...3
        for k in 0...3
          @bigrams[i][k]*=@magicnumber
        end
      end
      @bigrams[@history[@history.size-2]-1][move-1]+=1
    end
  end
  
  def predict
    ret=@bigrams[@history.last-1]
    total=ret[0]+ret[1]+ret[2]
    return nil if total==0
    for i in 0...3
      ret[i]/=total
    end
    ret[0],ret[1],ret[2]=ret[(@flip)%3],ret[(1+@flip)%3],ret[(2+@flip)%3]
    @prediction=ret
    return ret
  end
end

class Result_predictor < Predictor
  
  def initialize
    super
    @magicnumber=0.96
    @results=[[0,0,0],[0,0,0],[0,0,0]]
  end
  
  def feed(move,type)
    super(move,type)
    return if type!=1||@result.compact.size==0
    for i in 0...3
        for k in 0...3
          @results[i][k]*=@magicnumber
        end
    end
    @results[@result.last+1][move-1]+=1
  end
  
  def predict
    ret=@results[@result.last+1]
    agg=ret[0]+ret[1]+ret[2]
    return nil if agg==0
    for i in 0...3
      ret[i]/=agg
    end
    ret[0],ret[1],ret[2]=ret[(@flip)%3],ret[(1+@flip)%3],ret[(2+@flip)%3]
    @prediction=ret
    return ret
  end
end

class Response_predictor < Predictor
  def initialize
    super
    @magicnumber=0.96
    @response=[[0,0,0],[0,0,0],[0,0,0]]
  end
  
  def feed(move,type)
    super(move,type)
    return if type!=1
    return if @self.size<=1
    for i in 0...3
        for k in 0...3
          @response[i][k]*=@magicnumber
        end
    end
    @response[@self.last-1][move-1]+=1
  end
  
  def predict
    ret=@response[@self.last-1]
    agg=ret[0]+ret[1]+ret[2]
    return nil if agg==0

    for i in 0...3
      ret[i]/=agg
    end
    ret[0],ret[1],ret[2]=ret[(@flip)%3],ret[(1+@flip)%3],ret[(2+@flip)%3]
    @prediction=ret
    return ret
  end
end

class Self_bigram_predictor < Predictor
  
  def initialize
    super
    @bigrams=[[0,0,0],[0,0,0],[0,0,0]]
    @magicnumber=0.95
  end
  
  def feed(move,type)
    super(move,type)
    if type==2
      for i in 0...3
        for k in 0...3
          @bigrams[i][k]*=@magicnumber
        end
      end
      @bigrams[@self[@self.size-2]-1][move-1]+=1
    end
  end
  
  def predict
    ret=@bigrams[@self.last-1]
    total=ret[0]+ret[1]+ret[2]
    return nil if total==0
    for i in 0...3
      ret[i]/=total
    end
    ret=[ret[2],ret[0],ret[1]]
    ret[0],ret[1],ret[2]=ret[(@flip)%3],ret[(1+@flip)%3],ret[(2+@flip)%3]
    @prediction=ret
    return ret
  end
end

class LongPatternMatcher < Predictor
  
  def initialize
    super
    @expectation=0.0
  end
  
  def predict
    len = @history.length;
    last = @history[0]
    ret = [0,0,0]
    for x in 3...25
      if @history[len-1-x]==@history[len-1]
        ret[@history[len-x]-1]+=x
      end
    end
    total=ret[0]+ret[1]+ret[2]
    return nil if ret.max==0.0
    for i in 0...3
      ret[i]/=total
    end
    ret[0],ret[1],ret[2]=ret[(@flip)%3],ret[(1+@flip)%3],ret[(2+@flip)%3]
    @prediction=ret
    return ret
  end
  
end

class SelfPatternMatcher < Predictor
  
  def initialize
    super
    @expectation=0.0
  end
  
  def predict
    len = @self.length;
    last = @self[0]
    ret = [0,0,0]
    for x in 3...len/2
      if @self[len-1-x]==@self[len-1]
        ret[@self[len-x]-1]+=x
      end
    end
    total=ret[0]+ret[1]+ret[2]
    return nil if ret.max==0.0
    for i in 0...3
      ret[i]/=total
    end
    ret=[ret[2],ret[0],ret[1]]
    ret[0],ret[1],ret[2]=ret[(@flip)%3],ret[(1+@flip)%3],ret[(2+@flip)%3]
    @prediction=ret
    return ret
  end
  
end

instance=Zfeng.new
instance.start
