#!/usr/bin/python
import sys
import os
from optparse import OptionParser, OptionGroup


# Function to:
#   - load config file in memory
def load_config(file):
    f = open(file)
    str = f.read().replace('=>', ':')
    #print str
    cfg = eval(str)
    return cfg


# Function to:
#   - parse command line options
def parseCmdline():
    parser = OptionParser(prog="participant_sizer", add_help_option=False)
    parser.disable_interspersed_args()
    
    parser.add_option("--participant", "-p", help="participant name; map to global.config[participant]")

    parser.set_defaults(verbose=0, quiet=0)
    #parser.set_usage("How to use")
    (options, args) = parser.parse_args()
    
    return (parser, options, args)


# Function to 
#   - execute real work
def main():
    # get command line options
    parser, options, args = parseCmdline()

    # load global config config file
    global_conf = load_config("./global.config")

    par_name = options.participant
    
    sys.path.insert(0, './participants')
    if not global_conf['participant'][par_name]:
        print "ERROR: no participant: " + par_name + " defined in global.config!"
    
    md_name = os.path.splitext(global_conf['participant'][par_name]['file'])[0]
    class_name = global_conf['participant'][par_name]['class']
    md = __import__(md_name)
    cls = eval("md" + "." + class_name)
    #print dir(cls)

    print "Started a participant: " + par_name
    amqp_conf = global_conf['amqp']
    obj = cls(ruote_queue = global_conf['participant'][par_name]['queue'], 
                        amqp_host = amqp_conf['host'], 
                        amqp_user = amqp_conf['user'], 
                        amqp_pass = amqp_conf['pass'],
                        amqp_vhost = amqp_conf['vhost'])
    obj.run()

if __name__ == "__main__":
    main()


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



