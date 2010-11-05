#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
import os
import random
import time
from optparse import OptionParser, OptionGroup
from  RuoteAMQP.workitem import Workitem
from  RuoteAMQP.participant import Participant
import simplejson as json

# Class to
#   - real participant imlemented here
class Resizer(Participant):
    execute_num = 0

    def consume(self):
        wi = self.workitem
        # To do here what you want to do 
        Resizer.execute_num = Resizer.execute_num + 1
        print "resizer [ver: "+wi.fields()['version']+" | num: "+str(Resizer.execute_num)+"]"
        wi.set_result(True)

# Function to:
#   - parse command line options
def parseCmdline():
    parser = OptionParser(prog="participant_sizer", add_help_option=False)
    parser.disable_interspersed_args()
    
    parser.add_option("--config", "-c", help="test case config file")
    parser.add_option("--out", "-o", help="output folder, also using as workarea")

    parser.set_defaults(verbose=0, quiet=0)
    #parser.set_usage("How to use")
    (options, args) = parser.parse_args()
    
    return (parser, options, args)

# Function to:
#   - load config file in memory
def load_config(file):
    f = open(file)
    str = f.read().replace('=>', ':')
    #print str
    cfg = eval(str)
    return cfg

# Function to 
#   - execute real work
def main():
    # get command line options
    parser, options, args = parseCmdline()

    # load global config config file
    global_conf = load_config("./global.config")

    print "Started a participant: resizer"
    amqp_conf = global_conf['amqp']
    resizer = Resizer(ruote_queue = global_conf['participant']['resizer']['queue'], 
                        amqp_host = amqp_conf['host'], 
                        amqp_user = amqp_conf['user'], 
                        amqp_pass = amqp_conf['pass'],
                        amqp_vhost = amqp_conf['vhost'])
    resizer.run()

if __name__ == "__main__":
    main()

