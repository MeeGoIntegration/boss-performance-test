#!/usr/bin/python
from  RuoteAMQP.participant import Participant
import datetime



# Class to
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
        self.logger = None

    def init_case(fields):
        self.case = fields['case_name']
        self.logger = self.getLogger()

    def init_iteration(fields):
        self.iteration = fields['iteration']
        self.load = fields['load']
        self.start_t = datetime.datetime.now()
    
    def reset_iteration():
        self.iteration = 0
        self.start_cnt = 0
        self.end_cnt = 0
        self.start_t = 0
        self.end_t = 0
        self.load = 0
        self.case = ""

    def getLogger():
        import logging

        logger = logging.getLogger()
        hdlr = logging.FileHandler(self.case)
        logger.addHandler(hdlr)
        return logger

    def consume(self):
        wi = self.workitem
        fields = wi.fields()

        if fields['dirty'] == 0:
            fields['dirty'] = 1

            if self.start_cnt == 0:
                init_iteration(fields)
                if fields['case_name'] != self.case:
                    init_case(fields)

                # log to file
                #self.logger.info("---------Case %s Iteratoin %s Load %s------------", )
                print "Case %s Iteration %d Load %d" %(self.case, self.iteration, self.load)

            self.start_cnt += 1
        else:
            if self.end_cnt == self.load:
                self.end_t = datetime.datetime.now()
                duration = (self.end_t - self.start_t).seconds
                rate = self.load/duration
                # log to file
                print "duration: %d" %duration
                print "rate" %rate
                print "----------------------"

                self.reset_iteration()

            self.end_cnt += 1

        wi.set_result(True)


def main():
    host_name = "localhost"
    vhost = "boss"
    user_name = "boss"
    user_password = "boss"
    queue = "pilot"

    print "Started a participant: pilot"
    p = Pilot(ruote_queue=queue, amqp_host=host_name, amqp_user=user_name, amqp_pass=user_password, amqp_vhost=vhost)
    p.run()

if __name__ == "__main__":
    main()


