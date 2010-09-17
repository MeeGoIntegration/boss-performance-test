require 'dbm'

module Ruote

    INTERESTING_ACTIONS = ["launch", "terminated", "dispatch", "receive", "dispatched"]

    #
    # A helper logger for quickstart examples.
    #
    class DBMLogger

        @@count = 0
        @@max = 0
        def initialize (*opts)

            context, db_path = opts 
            
            db_path = "./msgs.dbm" if db_path.nil?
            @db_path = db_path 
            DBM.open(@db_path) do |db|
                db.clear
            end
            @db = DBM.open(@db_path)

            @context = context
            @context.worker.subscribe(:all, self) if @context.worker
            @msgs_h = Hash.new
        end

        def notify (msg)

            #puts "+++++++++++++++++notify+++++++++++++++++++"
            #p msg
            #t1 = Time.now
            
            wfid = msg["wfid"] || (msg["fei"] && msg["fei"]["wfid"])
            #puts "++++++++++++wfid is #{wfid}";

            return unless wfid

            return unless INTERESTING_ACTIONS.include?(msg["action"])

            puts "-----deal with action: #{msg['action']}"

            # cache msg
            @msgs_h[wfid] = Array.new if @msgs_h[wfid].nil?
            @msgs_h[wfid] << msg

            return unless msg["action"] == "terminated"

            # persist msgs to db    
            #DBM.open(@db_path) do |db|
                @@count += 1
                puts "----------------write to db: #{@@count}"
                @db[wfid] = Marshal.dump(@msgs_h[wfid])
                @db.close if @@count == 100000
                puts "----------------finished #{@@count}"
            #end
            #t1 = Time.now - t1
            #@@max = t1 if t1 > @@max
            #puts "----------------write to db: #{@@count}, funtion duration: #{@@max}"
        end
    end
end
