#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
import os
import random
import time
from optparse import OptionParser, OptionGroup

# Just until Ruote-AMQP is in a proper place
sys.path.append(os.path.dirname(__file__)+"/../../integration")

from  RuoteAMQP.workitem import Workitem
from  RuoteAMQP.participant import Participant
import simplejson as json

class Resizer(Participant):
    execute_num = 0

    def consume(self):
        wi = self.workitem
        # To do here what you want to do 
        Resizer.execute_num = Resizer.execute_num + 1
        print "resizer [ver: "+wi.fields()['version']+" | num: "+str(Resizer.execute_num)+"]"
        wi.set_result(True)

def parseCmdline():
    parser = OptionParser(prog="participant_sizer", add_help_option=False)
    parser.disable_interspersed_args()
    parser.add_option("--host", "-h", help="amqp host")
    parser.add_option("--user", "-u", help="amqp user")
    parser.add_option("--password", "-p", help="amqp password")
    parser.add_option("--vhost", "-v", help="amqp vhost")
    parser.add_option("--queue", "-q", help="ruote queue")

    parser.set_defaults(verbose=0, quiet=0)
    #parser.set_usage("How to use")
    (options, args) = parser.parse_args()
    
    return (parser, options, args)

def main():
    host_name = "amqpvm"
    user_name = "ruote"
    user_password = "ruote"
    vhost = "ruote-test"
    queue = "sizer"

    parser, options, args = parseCmdline()
    if not options.queue:
        parser.print_help()
        return
    if options.host:
        host_name = options.host
    if options.user:
        user_name = options.user
    if options.password:
        user_password = options.password
    if options.vhost:
        vhost = options.vhost
    if options.queue:
        queue = options.queue

    print "Started a participant: resizer"
    resizer = Resizer(ruote_queue=queue, amqp_host=host_name, 
                  amqp_user=user_name, amqp_pass=user_password,amqp_vhost=vhost)
    resizer.run()

if __name__ == "__main__":
    main()

