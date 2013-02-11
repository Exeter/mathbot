class Zfeng

  attr_accessor :history, :self, :current, :result, :weight, :count, :accuracy, :prediction, :overturn, :humancount, :accuracy, :total, :flip, :lastflip
  def initialize()
    @history=[]
    @self=[]
    @current=0
    @result=[]
    @count=[0,0,0]
    @accurate=[0,0,0,0,0]
    @accuracy=[1,1,1,1,1]
    @prediction=[[]]
    $ALGORITHM_NUMBER=2
    $RANDOM=false
    @flip=[false,false,false]
    @lastflip=[0,0,0,0,0]
    @overturn_threshold=(1.0/3)-(0.67448/6)
    @random=1.0/3-0.05
    @humancount=[0,0,0]
    @total=0
    @extra_command=[""]
  end

  def getInput
    if !$RANDOM
    input=""
    input=STDIN.getc()
    input=STDIN.getc() if input=="\n"
    if input!="R" && input!="S" && input!="P"
      print "Illegal Input, please try again"
      return
    end
    case input
    when "R"
      @current=1
    when "P"
      @current=2
    when "S"
      @current=3
    end
    else @current=getRandom end
    @history.push(@current)
    @humancount=[0,0,0]
    for i in 0...3
      for k in 0...total
        if @history[k]==i+1
          @humancount[i]+=0.9**(total-k-1)
        end
      end
    end
  end

  def getRandom
    return (Random.rand*3).floor+1
  end

  def process
    while(@total<=1000)
      predict
    end
    print "Accuracies >>"+@accuracy.to_s+"\n"
  end

  def predict_unigram
    total_weighted=0
    for k in 0...total
        total_weighted+=0.9**(total-k-1)
    end
    ret=[@humancount[0].to_f/total_weighted,@humancount[1].to_f/total_weighted,@humancount[2].to_f/total_weighted]
    
    agg=ret[0]+ret[1]+ret[2]
    for i in 0...3
      ret[i]/=agg
    end
    if @flip[0]
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    return ret
  end
  
  def predict_bigram
    temp=[0,0,0]
    match=0
    for i in 0...@history.size-1
      if @history[i]==@history.last
        temp[@history[i+1]-1]+=0.95**(@history.size-i-2)
        match+=0.95**(@history.size-i-2)
      end
    end
    ret=[]
    for i in 0...temp.size
      break if match==0
      ret[i]=temp[i].to_f/match
    end
    for i in 0...3
      if ret[i]==nil
        ret[i]=0
      end
    end
    agg=ret[0]+ret[1]+ret[2]
    return nil if agg==0
    for i in 0...3
      ret[i]/=agg
    end
    if @flip[2]
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    return ret
  end
  
  def predict_result
    temp=[0,0,0]
    match=0
    for i in 0...@result.size-1
      if @result[i]==@result.last
        temp[@history[i+1]-1]+=0.95**(@history.size-i-2)
        match+=0.9**(@history.size-i-2)
      end
    end
   
    ret=[]
    for i in 0...temp.size
      break if match==0
      ret[i]=temp[i].to_f/match
    end
    for i in 0...3
      if ret[i]==nil
        ret[i]=0
      end
    end
    agg=ret[0]+ret[1]+ret[2]
    return nil if agg==0
     
    for i in 0...3
      ret[i]/=agg
    end
    if @flip[1]
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    return ret
  end

  def predict_response
    temp=[0,0,0]
    match=0
    for i in 0...@self.size-1
      if @self[i]==@self.last
        temp[@history[i+1]-1]+=0.9**(@history.size-i-2)
        match+=0.9**(@history.size-i-2)
      end
    end
   
    ret=[]
    for i in 0...temp.size
      break if match==0
      ret[i]=temp[i].to_f/match
    end
    for i in 0...3
      if ret[i]==nil
        ret[i]=0
      end
    end
    agg=ret[0]+ret[1]+ret[2]
    return nil if agg==0
     
    for i in 0...3
      ret[i]/=agg
    end
    if @flip[1]
      max=ret.index(ret.max)
      temp=ret.max
      ret[max]=ret[(max==0?2:max-1)]
      ret[(max==0?2:max-1)]=temp
    end
    return ret
  end

  def assimilate
    @prediction[0]=predict_unigram
    @prediction[1]=predict_result
    @prediction[2]=predict_bigram
    @prediction[3]=predict_response
    @prediction[4]=[]
    print "Unigram predictor predicts " + @prediction[0].to_s+"\n"
    print "Result predictor predicts " + (@prediction[1].to_s) + "\n"
    print "Bigram predictor predicts " + (@prediction[2].to_s) + "\n"
    print "Response predictor predicts " + @prediction[3].to_s + "\n"
    result=[0,0,0]
    for i in 0...@prediction.size
      next if @prediction[i]==nil||i==4
      result[0]+=@prediction[i][0]*@accuracy[i]
      result[1]+=@prediction[i][1]*@accuracy[i]
      result[2]+=@prediction[i][2]*@accuracy[i]
    end
    agg=result[0]+result[1]+result[2]
    for i in 0...3
      result[i]/=agg
    end
    @prediction[4]=result
    print "Aggregate is betting on " + result.to_s + "\n"
    decision=((result.index(result.max)+2)%3==0?3:((result.index(result.max)+1)+1)%3)
    return decision
  end

  def predict
    move=0
    if @history.length<=1
      move=getRandom
    else
      move=assimilate
    end
    post_predict(move)
  end

  def post_predict(move)
    if @accuracy[4]<=@random
      move=getRandom
      print "Random Fallback in effect\n"
    end
    @self.push(move)
    @total+=1
    getInput
    print "Computer plays: "
    case move
    when 1
      print "Rock"
    when 2
      print "Paper"
    when 3
      print "Scissor"
    end
    print "\n"
    result=move-@current
    case result
    when -2,1
      @result.push(1)
      @count[0]+=1
      print "You lost!"
    when 2,-1
      @result.push(-1)
      @count[1]+=1
      print "You won!"
    else
      @result.push(0)
      @count[2]+=1
      print "You tied!"
    end
    print "\n"
    for i in 0...@prediction.size
      break if total<=2
      next if @prediction[i]==nil
      if @prediction[i].index(@prediction[i].max)+1==@current
        @accurate[i]+=1
      end
      @accuracy[i]=1.0/2*@accuracy[i]+1.0/2*@accurate[i].to_f/(total-2)
    end
    flip
    print "Accuracies >>"+@accuracy.to_s+"\n"
    print "Scores:" + "\n"
    print "Computer Win:" + @count[0].to_s + " Percentage:"+(@count[0].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n"
    print "Tie:"  + @count[2].to_s + " Percentage:"+(@count[2].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n"
    print "Computer Lost:"  + @count[1].to_s + " Percentage:"+(@count[1].to_f/(@count[0]+@count[1]+@count[2])).to_s+ "\n\n"
  end

  def flip
    for i in 0...@accuracy.size
      if @accuracy[i]<@overturn_threshold && total-@lastflip[i]>=10
        @flip[i]=!@flip[i]
        @lastflip[i]=total
        print "Predictor "+ i.to_s + " has been flipped with an accuracy of "+@accuracy[i].to_s+"\n"
      end
    end
  end
  print "FLIP >> "+@flip.to_s+"\n"
end

example=Zfeng.new
example.process