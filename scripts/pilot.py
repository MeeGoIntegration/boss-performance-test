#!/usr/bin/python
from  RuoteAMQP.participant import Participant
import datetime
import logging
import os
from decimal import *
#getcontext().prec = 3


# Class 
#   - implement pilot to record workflow information
class Pilot(Participant):

    def __init__(self, ruote_queue, amqp_host, amqp_user, amqp_pass, amqp_vhost):
        Participant.__init__(self, ruote_queue, amqp_host, amqp_user, amqp_pass, amqp_vhost)

        self.iteration = 0
        self.start_cnt = 0
        self.end_cnt = 0
        self.start_t = 0
        self.end_t = 0
        self.load = 0
        self.case = ""
        self.file_hdlr = None
        self.initLogger()

    def init_case(self, fields):
        print "enter init_case..."
        self.case = fields['case_name']
        file = fields['output'] + '/' + self.case + '.log'
        if os.path.exists(file):
            os.remove(file)
        self.updateLogger(file)

    def init_iteration(self, fields):
        self.iteration = fields['iteration']
        self.load = fields['load']
        self.start_t = datetime.datetime.now()

    def finish_iteration(self, fields):
        self.iteration = 0
        self.start_cnt = 0
        self.end_cnt = 0
        self.start_t = 0
        self.end_t = 0
        self.load = 0
        flag = fields['output'] + '/' + 'iteration_finish'
        open(flag, 'w')

    def initLogger(self):
        self.logger = logging.getLogger()
        console = logging.StreamHandler()
        self.logger.addHandler(console)
        self.logger.setLevel(logging.NOTSET)

    def updateLogger(self, file):
        if not self.file_hdlr:
            self.logger.removeHandler(self.file_hdlr)
        self.file_hdlr = logging.FileHandler(file)
        self.logger.addHandler(self.file_hdlr)

    def consume(self):
        #print "enter consume..."
        wi = self.workitem
        fields = wi.fields()

        if fields['dirty'] == 0:
            fields['dirty'] = 1

            if self.start_cnt == 0:
                self.init_iteration(fields)
                if fields['case_name'] != self.case:
                    self.init_case(fields)

                # log to file and stdout
                self.logger.info("\n== Case: %s, Iteration: %d, Load: %d" %(self.case, self.iteration, self.load))
                self.logger.info("Start:\t\t%s" %(self.start_t))

            self.start_cnt += 1
        else:
            self.end_cnt += 1

            if self.end_cnt == self.load:
                self.end_t = datetime.datetime.now()
                duration = Decimal(str((self.end_t - self.start_t).microseconds))/Decimal('1000000')
                print (self.end_t - self.start_t).microseconds
                print Decimal(str((self.end_t - self.start_t).microseconds))
                rate = Decimal(self.load)/duration
                # log to file and stdout
                self.logger.info("End:\t\t%s" %(self.end_t))
                self.logger.info("Duration:\t%d seconds" %duration)
                self.logger.info("Rate:\t\t%d workflows/second" %rate)
                self.logger.info("== END")

                self.finish_iteration(fields)

        import time
        time.sleep(0.5)
        wi.set_result(True)

def main():
    host_name = "localhost"
    vhost = "boss"
    user_name = "boss"
    user_password = "boss"
    queue = "pilot"

    print "Starting participant \"pilot\"..."
    p = Pilot(ruote_queue=queue, 
                amqp_host=host_name, 
                amqp_user=user_name, 
                amqp_pass=user_password, 
                amqp_vhost=vhost)
    p.register("pilot", {"queue":"pilot"})
    p.run()

if __name__ == "__main__":
    main()


