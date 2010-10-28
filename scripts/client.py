# -*- coding: utf-8 -*-

from optparse import OptionParser, OptionGroup
from amqplib import client_0_8 as amqp
import simplejson as json
import sys
import threading
import time
import os

def parseCmdline():
    parser = OptionParser(prog="client", add_help_option=False)
    parser.disable_interspersed_args()
   
    #parser.add_option("--version", action="version",
    #                  help="Show version number and exit")
    parser.add_option("--channel", "-c", help="single channel or multiple channel")
    parser.add_option("--load", "-l", type="int", help="load number")
    parser.add_option("--iteration", "-i", type="int", help="iteration number")
    parser.add_option("--workflow", "-w", help="Workflow message")
    parser.add_option("--host", "-h", help="amqp host")
    parser.add_option("--user", "-u", help="amqp user")
    parser.add_option("--password", "-p", help="amqp password")
    parser.add_option("--vhost", "-v", help="amqp vhost")

    parser.set_defaults(verbose=0, quiet=0)
    #parser.set_usage("How to use")
    (options, args) = parser.parse_args()
    
    return (parser, options, args)

def main():
    channel = "multiple"
    conn = None
    chan = None
    load = 1000
    iteration = 1
    host_name = "amqpvm"
    user_name = "ruote"
    user_password = "ruote"
    vhost = "ruote-test"
    workflow = {
        "definition": "no any workflow definition",
        "fields" : {
            "version" : "1",
	    "thread_count" : 1000
            }
        }

    parser, options, args = parseCmdline()

    if not options.workflow:
        parser.print_help()
    else:
        #print "..."
        if options.channel:
            channel = options.channel
        if options.load:
            load = options.load
        if options.iteration:
            iteration = options.iteration
        if options.host:
            host_name = options.host
        if options.user:
            user_name = options.user
        if options.password:
            user_password = options.password
        if options.vhost:
            vhost = options.vhost
        workflow["definition"] = options.workflow
        workflow["thread_count"] = load * iteration
        #print "Run..."
        conn = amqp.Connection(host=host_name, userid=user_name,
                       password=user_password, virtual_host=vhost, insist=False)
        if channel == "single":
            chan = conn.channel()

        if os.access("./.load_over", os.F_OK):
            os.remove("./.load_over")

        for j in range(iteration):
            for i in range(load):
                workflow["fields"]["version"] = str(i+1)
                t = RequestThread(conn, chan, channel, i+1, workflow)
                t.run()

            print "-----------waiting....--------------"
            #time.sleep(3)
            while (not os.access("./.load_over", os.F_OK)):
                time.sleep(1)
            os.remove("./.load_over")
            time.sleep(10)
        if channel == "single":
            chan.close()
        conn.close()
        f = open("/tmp/boss.pipe", "w")
        f.write("finish")
        f.close()
        raw_input("All requests have been sent. Enter to close this window...")

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
        msg = amqp.Message(json.dumps(self._pdef))
        msg.properties["delivery_mode"] = 2
        self._chan.basic_publish(msg, exchange='', routing_key='ruote_workitems')
        if self._channel == "multiple":
            self._chan.close()
        print "Request "+str(self._id)+" : OK"

if __name__ == "__main__":
    main()

