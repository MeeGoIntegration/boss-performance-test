from amqplib import client_0_8 as amqp
import simplejson as json
import sys
import threading
import time


#if len(sys.argv) != 2:
#    print "Usage: python launch.py <version>"
#    sys.exit(1)

# Specify a process definition
print "usage: python client.py [thread_count 1-1000] [process_type 1(sequence) or 2(concurrence)]"
print "e.g. python client.py 20 2"

thread_count = 1
process_def = 1

version = 1

argv_count = len(sys.argv)
if  argv_count > 1:
    thread_count = int(sys.argv[1])
    if thread_count < 1:
        thread_count = 1
    elif thread_count > 10000:
        #print "> 1000 : "+str(thread_count)
        thread_count = 10000
        
if argv_count > 2:
    process_def = int(sys.argv[2])


pdef_1 = {
    "definition": """
        Ruote.process_definition :name => 'test_sequence' do
          sequence do
            sizer
          end
        end
      """,
    "fields" : {
        "version" : "1"
        }
    }

pdef_2 = {
    "definition": """
        Ruote.process_definition :name => 'test_concurrence' do
          concurrence do
            sizer
            developer
            sizer
            developer
          end
        end
      """,
    "fields" : {
        "version" : "1"
        }
    }

# Connect to the amqp server
conn = amqp.Connection(host="amqpvm", userid="ruote",
                       password="ruote", virtual_host="ruote-test", insist=False)
chan = conn.channel()

# Encode the message as json
#print "Thread: "+str(thread_count)
#print "pdef: "+str(process_def)


class MyThread(threading.Thread):
    def __init__(self,id, pdef):
        threading.Thread.__init__(self)
        self._id = id
        self._pdef = pdef
    def run(self):
        #print "version: "+str(pdef["fields"]["version"])
        msg = amqp.Message(json.dumps(pdef))
        msg.properties["delivery_mode"] = 2
        chan.basic_publish(msg, exchange='', routing_key='ruote_workitems')
        print str(self._id)+" : OK"


pdef = pdef_1
if process_def == 2:
    pdef = pdef_2


for i in range(thread_count):
    j = i + 1
    print str(j)+" : START"
    pdef["fields"]["version"] = str(j)
    t = MyThread(j, pdef)
    t.run()
#msg = amqp.Message(json.dumps(pdef))
## delivery_mode=2 is persistent
#msg.properties["delivery_mode"] = 2
#
## Publish the message.
#
## Notice that this is sent to the anonymous/'' exchange (which is
## different to 'amq.direct') with a routing_key for the queue
#chan.basic_publish(msg, exchange='', routing_key='ruote_workitems')
#
## and wrap up.
#chan.close()
#conn.close()

