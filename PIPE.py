from subprocess import Popen, PIPE, STDOUT
import time

print 'launching slave processes...'
zfeng = Popen(['ruby','RPS.rb'], stdin=PIPE, stdout=PIPE, stderr=STDOUT)
morple = Popen(['./a.out'], stdin=PIPE, stdout=PIPE, stderr=STDOUT)

x=0
count=[0,0,0]
while x<1000:
    # check if slave has terminated:
    if zfeng.poll() is not None or morple.poll() is not None:
        print 'slave has terminated.'
        morple.kill()
        zfeng.kill()
        exit()
    # read one line, remove newline chars and trailing spaces:
    fengout = zfeng.stdout.read(1)
    morpleout = morple.stdout.read(1)
    fengtemp=0
    morpletemp=0
    if fengout=='R':
        fengtemp=0
    elif fengout=='P':
        fengtemp=1
    else:
        fengtemp=2
    if morpleout=='R':
        morpletemp=0
    elif morpleout=='P':
        morpletemp=1
    else:
        morpletemp=2
    if (fengtemp-morpletemp+3)%3==1:
        count[2]+=1
    elif fengtemp==morpletemp:
        count[1]+=1
    else:
        count[0]+=1
    print morpleout + " VS "+fengout
    # write that line to slave's stdin
    try:
        morple.stdin.write(fengout)
        zfeng.stdin.write(morpleout)
    except IOError, e:
        print "ERROR"
        morple.kill()
    x+=1
print count
morple.kill()
zfeng.kill()