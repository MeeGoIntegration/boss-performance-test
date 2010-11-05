#!/usr/bin/python
from  RuoteAMQP.participant import Participant

# Class to
#   - real participant imlemented here
class Sizer(Participant):
    execute_num = 0

    def consume(self):
        wi = self.workitem
        # To do here what you want to do 
        Sizer.execute_num = Sizer.execute_num + 1
        print "sizer [ver: "+wi.fields()['version']+" | num: "+str(Sizer.execute_num)+"]"
        wi.set_result(True)

