from subprocess import Popen, PIPE, STDOUT
import time

print 'launching slave process...'
zfeng = Popen(['ruby', 'RPS.rb'], stdin=PIPE, stdout=PIPE, stderr=STDOUT)
morple = Popen(['./a.out'], stdin=PIPE, stdout=PIPE, stderr=STDOUT)

while True:
    while True:
        # check if slave has terminated:
        if slave.poll() is not None:
            print 'slave has terminated.'
            exit()
        # read one line, remove newline chars and trailing spaces:
        line = slave.stdout.readline().rstrip()
        #print 'line:', line
        if line == '[end]':
            break
        result.append(line)
    # read user input, expression to be evaluated:
    line = raw_input('Enter expression or exit:')
    # write that line to slave's stdin
    slave.stdin.write(line+'\n')
    # result will be a list of lines:
    result = []
    # read slave output line by line, until we reach "[end]"
    while True:
        # check if slave has terminated:
        if slave.poll() is not None:
            print 'slave has terminated.'
            exit()
        # read one line, remove newline chars and trailing spaces:
        line = slave.stdout.readline()
        #print 'line:', line
        if line == "[end]\n":
            break
        result.append(line)
    print "".join(result)