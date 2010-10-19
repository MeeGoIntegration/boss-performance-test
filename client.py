from amqplib import client_0_8 as amqp
import simplejson as json
import sys
import threading
import time
import os

#if len(sys.argv) != 2:
#    print "Usage: python launch.py <version>"
#    sys.exit(1)

# Specify a process definition
print "usage: python client.py [load(integer)] [iteration(integer)]"
print "       note: it's set as 1 if missing iteration option"
print "e.g. python client.py 500 10"

thread_count = 1
repeat_count = 1
process_def = 1
msg_log_dir = "./.results_msg"
version = 1

argv_count = len(sys.argv)
#print sys.argv
if  argv_count > 1:
    thread_count = int(sys.argv[1])
    if thread_count < 1:
        thread_count = 1

if argv_count > 2:
    repeat_count = int(sys.argv[2])

pdef_1 = {
    "definition": """
        Ruote.process_definition :name => 'test_sequence' do
          sequence do
            sizer
            resizer
          end
        end
      """,
    "fields" : {
        "version" : "1",
	"thread_count" : thread_count
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
        "version" : "1",
        "thread_count" : thread_count
        }
    }

pdef = pdef_1

# Connect to the amqp server
conn = amqp.Connection(host="amqpvm", userid="ruote",
                       password="ruote", virtual_host="ruote-test", insist=False)
#chan = conn.channel()

class RequestThread(threading.Thread):
    def __init__(self,id, pdef):
        threading.Thread.__init__(self)
        self._id = id
        self._pdef = pdef
    def run(self):
        chan = conn.channel()
        msg = amqp.Message(json.dumps(pdef))
        msg.properties["delivery_mode"] = 2
        chan.basic_publish(msg, exchange='', routing_key='ruote_workitems')
        chan.close()
        print str(self._id)+" : OK"


if os.access("./test_over", os.F_OK):
    os.remove("./test_over")

for n in range(repeat_count):
    for i in range(thread_count):
        j = i + 1
        print str(j)+" : START"
        pdef["fields"]["version"] = str(j)
        t = RequestThread(j, pdef)
        t.run()

    print "---------------------Sleeping-------------------------"
    time.sleep(3)
    while (not os.access("./test_over", os.F_OK)):
        time.sleep(1)
    os.remove("./test_over")
    print "------------------------------------------------------"
    time.sleep(10)

def monitor_test():
    raw_input("Enter to close this window...")

conn.close()
monitor_test()
