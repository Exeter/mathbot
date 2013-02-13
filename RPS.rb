$RANDOM=false
$DEV=false
$overturn_threshold=(1.0/3)-(0.67448/6)
$random=1.0/3-0.05

class Zfeng

  attr_accessor :predictors, :prediction, :total, :current, :accurate, :accuracy, :count

  def initialize()
    @current=0
    @count=[0,0,0]
    @predictors=[Unigram_predictor.new,Bigram_predictor.new,Result_predictor.new,Response_predictor.new]
    @prediction=[]
    @total=0
    @accurate=[0,0]
    @accuracy=[1,1]
  end

 # Main method
  def start
    print getRandom
    #print "[end]\n"
    #STDOUT.flush
    while(@total<=10000)
      predict
    end
    #print "Accuracies >>"+@accuracy.to_s+"\n"
    #print "Scores:" + "\n"
    #print "Computer Win:" + @count[0].to_s + " Percentage:"+(@count[0].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n"
    #print "Tie:"  + @count[2].to_s + " Percentage:"+(@count[2].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n"
    #print "Computer Lost:"  + @count[1].to_s + " Percentage:"+(@count[1].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n\n"
  end

  # Get input from console
  def getInput
    if !$RANDOM
      input=STDIN.getc()
      case input
        when "R"
          @current=1
        when "P"
          @current=2
        when "S"
          @current=3
      end
    else
      @current=getRandom
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
    if !$RANDOM && $DEV
      print "Unigram predictor predicts " + @prediction[0].to_s+"\n"
      print "Result predictor predicts " + (@prediction[1].to_s) + "\n"
      print "Bigram predictor predicts " + (@prediction[2].to_s) + "\n"
      print "Response predictor predicts " + @prediction[3].to_s + "\n"
    end
    result=[0,0,0]
    for i in 0...@predictors.size
      next if @prediction[i]==nil
      result[0]+=@prediction[i][0]*(@predictors[i].accuracy+2*(@predictors[i].accuracy>=1.0/3?@predictors[i].accuracy-1.0/3:0))
      result[1]+=@prediction[i][1]*(@predictors[i].accuracy+2*(@predictors[i].accuracy>=1.0/3?@predictors[i].accuracy-1.0/3:0))
      result[2]+=@prediction[i][2]*(@predictors[i].accuracy+2*(@predictors[i].accuracy>=1.0/3?@predictors[i].accuracy-1.0/3:0))
    end

    agg=result[0]+result[1]+result[2]
    for i in 0...3
      result[i]/=agg
    end
    @prediction[4]=result
    @prediction[5]=[@prediction[4][2],@prediction[4][0],@prediction[4][1]]
    print "Aggregate is betting on " + result.to_s + "\n" if !$RANDOM&&$DEV
    if @accuracy[0]>=@accuracy[1]
      decision=((result.index(result.max)+2)%3==0?3:(result.index(result.max)+2)%3)
    else
      decision=((@prediction[5].index(@prediction[5].max)+2)%3==0?3:(@prediction[5].index(@prediction[5].max)+2)%3)
      print "Aggregate is flipped\n" if $DEV
    end
    #print "[end]\n"
    #STDOUT.flush
    return decision
  end

  def predict
    move=0
    if @total==0
      move=getRandom
    else
      move=assimilate
    end
    post_predict(move)
  end

  def post_predict(move)
    if @accuracy[0]<=$random&&@accuracy[1]<=$random
      @fallbackcount+=1
      if @fallbackcount>=5
        move=getRandom
        print "Random Fallback in effect\n" if $DEV
      end
    else
      @fallbackcount=0
    end
    feed_all(move,2)
    @total+=1
    getInput
    if !$RANDOM
      case move
        when 1
          print "R"
        when 2
          print "P"
        when 3
          print "S"
      end
    end
    result=move-@current
    case result
      when -2,1
        @count[0]+=1
        feed_all(1,3)
        #print "You lost!" if !$RANDOM
      when 2,-1
        @count[1]+=1
        feed_all(-1,3)
        #print "You won!" if !$RANDOM
    else
      @count[2]+=1
    feed_all(0,3)
    #print "You tied!" if !$RANDOM
    end
    #print "\n" if !$RANDOM
    for i in 4...6
      break if @total<=2
      if @prediction[i].index(@prediction[i].max)+1==@current
        @accurate[i-4]+=1
      end
        @accuracy[i-4]=1.0/2*@accuracy[i-4]+1.0/2*@accurate[i-4].to_f/(@total-2)
    end
    flip
    return if $RANDOM
    accuracies=[]
    for i in 0...@predictors.size
      accuracies[i]=@predictors[i].accuracy
    end
    accuracies.push(@accuracy[0])
    accuracies.push(@accuracy[1])
    #print "Accuracies >> "+accuracies.to_s+"\n" if $DEV
    #print "Aggregate accuracies >> "+@accuracy.to_s+"\n" if $DEV
    #print "Scores:" + "\n"
    #print "Computer Win:" + @count[0].to_s + " Percentage:"+(@count[0].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n"
    #print "Tie:"  + @count[2].to_s + " Percentage:"+(@count[2].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n"
    #print "Computer Lost:"  + @count[1].to_s + " Percentage:"+(@count[1].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n"
    #print "[end]\n"
    #STDOUT.flush
  end

  def flip
    for i in 0...@predictors.size
      if @predictors[i].accuracy<=$overturn_threshold && total-@predictors[i].lastflip>=10
        @predictors[i].flip=!@predictors[i].flip
        @predictors[i].lastflip=total
        #print "Predictor "+ i.to_s + " has been flipped with an accuracy of "+@predictors[i].accuracy.to_s+"\n"
      end
    end
  end
  
  def feed_all(move,type)
    for i in 0...@predictors.size
      @predictors[i].feed(move,type)
    end
  end 
end

class Predictor
  
  attr_accessor :history, :self, :result, :flip, :lastflip, :prediction, :accurate, :accuracy
  
  def initialize()
    @history=[]
    @self=[]
    @result=[]
    @flip=false
    @lastflip=0
    @prediction=[0,0,0]
    @accurate=0
  end
  
  # Feed the data to the predictor
  # 1. Human 2. Bot 3. Result
  def feed(move,type)
    case type
    when 1
      @history.push(move)
      if move==@prediction.index(@prediction.max)+1
        @accurate+=1
      end
    when 2
      @self.push(move)
    when 3
      @result.push(move)
    end
  end
end

class Unigram_predictor < Predictor
  
  attr_accessor :humancount, :magicnumber
  
  def initialize
    super
    @humancount=[0,0,0]
    @accuracy=1.0/3
    @magicnumber=0.8
  end
  
  def feed(move,type)
    super(move,type)
    return if type!=1
    for i in 0...@humancount.size
      @humancount[i]*=@magicnumber
    end
    @humancount[move-1]+=1.0
    return if @history.size==1
    @accuracy=0.5*@accuracy+0.5*(@accurate/(@history.size.to_f-1.0))
  end
  
  def predict
    total=(@humancount[0]+@humancount[1]+@humancount[2]).to_f
    ret=[@humancount[0]/total,@humancount[1]/total,@humancount[2]/total]
    agg=ret[0]+ret[1]+ret[2]
    for i in 0...3
      ret[i]/=agg
    end
    if @flip
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    @prediction=ret
    return ret
  end
end

class Bigram_predictor < Predictor
  
  attr_accessor :bigrams,:magicnumber
  
  def initialize
    super
    @bigrams=[[0,0,0],[0,0,0],[0,0,0]]
    @accuracy=1
    @magicnumber=0.95
  end
  
  def feed(move,type)
    super(move,type)
    if type==1
      for i in 0...3
        for k in 0...3
          @bigrams[i][k]*=@magicnumber
        end
      end
      @bigrams[@history.last-1][move-1]+=1
    end
  end
  
  def predict
    ret=@bigrams[@history.last-1]
    total=ret[0]+ret[1]+ret[2]
    return nil if total==0
    for i in 0...3
      ret[i]/=total
    end
    if @flip
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    @prediction=ret
    return ret
  end
end

class Result_predictor < Predictor
  
  attr_accessor :magicnumber, :results
  
  def initialize
    super
    @accuracy=1
    @magicnumber=0.9
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
    ret=@results[@result.last-1]
    agg=ret[0]+ret[1]+ret[2]
    return nil if agg==0
    for i in 0...3
      ret[i]/=agg
    end
    if @flip
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    @prediction=ret
    return ret
  end
end

class Response_predictor < Predictor
  attr_accessor :response, :magicnumber
  
  def initialize
    super
    @accuracy=1
    @magicnumber=0.95
    @response=[[0,0,0],[0,0,0],[0,0,0]]
  end
  
  def feed(move,type)
    super(move,type)
    return if type!=1
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
    if @flip
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    @prediction=ret
    return ret
  end
end

instance=Zfeng.new
instance.start
