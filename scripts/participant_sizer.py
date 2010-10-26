#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
import os
import random
import time

# Just until Ruote-AMQP is in a proper place
sys.path.append(os.path.dirname(__file__)+"/../../integration")

from  RuoteAMQP.workitem import Workitem
from  RuoteAMQP.participant import Participant
import simplejson as json

class MyPart(Participant):
    my_count = 0

    def consume(self):
        wi = self.workitem
        MyPart.my_count = MyPart.my_count + 1
        print "[ver: "+wi.fields()['version']+" | "+str(MyPart.my_count)+"]"
        wi.set_result(True)

print "Started a python participant"
p = MyPart(ruote_queue="sizer", amqp_host="amqpvm", amqp_vhost="ruote-test")
p.run()
