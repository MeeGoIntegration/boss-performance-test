#!/usr/bin/env python
# -*- coding: utf-8 -*-

from optparse import OptionParser, OptionGroup
from amqplib import client_0_8 as amqp
import simplejson as json
import sys
import threading
import time
import os

out = "/root/results/case_001"

def load_global_config():
    cfg = {
        "amqp" : {
	    "host" : "localhost",
            "user" : "boss",
	    "pass" : "boss",
            "vhost" : "boss"
	 }
    }
    return cfg

def load_case_config():
    cfg = {
        "case_name" : "case_001",
	"channel" : "single",
	"load" : 2,
	"iteration" : 1,
	"iteration_timeout" : 10
	}
    return cfg

workflow = {
         "definition" : """
	     Ruote.process_definition :name => 'boss-performance-test' do
	       sequence do
                 pilot
                 pilot
	       end
             end
	     """,
	   "fields" : {
	       "dirty" : 0,
	       "version" : 0
	       }
	   }

# Class to:
#   - send multiple workflows to engine in different threads concurrectly
class RequestThread(threading.Thread):
    def __init__(self,conn, chan, channel, id, pdef):
        threading.Thread.__init__(self)
        self._conn = conn
        self._chan = chan
        self._channel = channel
        self._id = id
        self._pdef = pdef
    def run(self):
        if self._channel == "multiple":
            self._chan = self._conn.channel()
        #print self._pdef
        msg = amqp.Message(json.dumps(self._pdef))
        msg.properties["delivery_mode"] = 2
        self._chan.basic_publish(msg, exchange='', routing_key='ruote_workitems')
        if self._channel == "multiple":
            self._chan.close()
        print "Request "+str(self._id)+" : OK"

# Function to:
#   - parse command line options
def parseCmdline():
    parser = OptionParser(prog="client", add_help_option=False)
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
    str = f.read()
    str = str.replace('=>', ':')
    #print str
    cfg = eval(str)
    return cfg


# Function to:
#   - execute real work
def main():
    # get command line options
    #parser, options, args = parseCmdline()
    #out = options.out

    # load global and case config files
    #global_conf = load_config("./global.config")
    #case_conf = load_config(options.config)
    global_conf = load_global_config()
    case_conf = load_case_config()

    # AMQP connection
    amqp_conf = global_conf['amqp']
    conn = amqp.Connection(host = amqp_conf['host'], 
                            userid = amqp_conf['user'], 
                            password = amqp_conf['pass'], 
                            virtual_host = amqp_conf['vhost'], 
                            insist = False)

    # AMQP channel
    channel_opt = case_conf['channel']
    chan = None
    if channel_opt == "single":
        chan = conn.channel()

    # clear finish flag file
    finish_flag = out + "/iteration_finish"
    if os.access(finish_flag, os.F_OK):
        os.remove(finish_flag)

    # get workflow core from config file
    #workflow_core_file = case_conf['workflow']
    #workflow_core_file = "./workflows/" + workflow_core_file
    #workflow_core = open(workflow_core_file).read()
    #print workflow_core

    # assemble workflow message
    #workflow = {}
    #workflow['definition'] = workflow_core
    #workflow['fields'] = {}
    workflow["fields"]["case_name"] = case_conf["case_name"]
    workflow["fields"]["iteration"] = case_conf["iteration"]
    workflow["fields"]["load"] = case_conf["load"]
    workflow["fields"]["output"] = out #"/root/results/case_001"
    #print workflow
    
    # get timeout as second
    timeout = case_conf["iteration_timeout"]
    timeout = timeout * 60 # seconds
    
    # send workflows to engine iteratively by load 
    ret = None
    for j in range(case_conf['iteration']):
        workflow["fields"]["iteration"] = (j+1)
        timer = 0
        for i in range(case_conf["load"]):
            workflow["fields"]["version"] = (i+1) #str(i+1)
            t = RequestThread(conn, chan, channel_opt, i+1, workflow)
            t.run()

        print "-----------waiting....--------------"
        print "\n"

        while True: 
            if (not os.access(finish_flag, os.F_OK)):
                time.sleep(1)
                timer = timer + 1
                print "\rwaiting time: " + str(timer),
                if timer > timeout:
                    print "ERROR: timeout for " + str(timeout) + " seconds!"
                    ret = "timeout"
                    break
            else:
                ret = "finish"
                os.remove(finish_flag)
                break
        
        if ret == "timeout":
            break

        time.sleep(10)

    # AMQP channel
    if channel_opt == "single":
        chan.close()

    # AMQP connection
    conn.close()

    # inform run.rb
    f = open(out + "/run.pipe", "w")
    f.write(ret + "\n")
    f.close()
    raw_input("finish")


if __name__ == "__main__":
    main()

