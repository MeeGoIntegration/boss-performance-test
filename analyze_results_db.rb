#!/usr/bin/env ruby

require 'rubygems'
require 'ruote'
require 'parsedate'
require 'dbm'

$time_data = {}
$time_data["start"] = Time.now
$time_data["end"] = Time.local(1970, 1, 1)

def analyze_time_data(db_path)
    db = DBM.open(db_path)
    db.values.each do |raw_msgs|
        msgs = Marshal.load(raw_msgs)
        collect_time_data(msgs)
    end
    db.close
    statistics_time_data()
    #p $time_data
end

def statistics_time_data()
    proc_durations, parti_durations = collect_durations()
    #p proc_durations
    #p parti_durations
    
    puts
    puts "+++++ time statistics data: test case"
    puts "Total: #{$time_data['duration']}"

    puts
    puts "+++++ time statistics data: processes"
    array_sum_and_aver(proc_durations, true)

    parti_durations.each do |name, durations|
        puts
        puts "+++++ time statistics data: participant #{name}"
        #p durations.sort
        array_sum_and_aver(durations, true)
    end
end

def collect_durations()
    proc_durations = []
    parti_durations = {}

    $time_data.values.each do |wfid_h|
        # filter out "start/end/duration"
        unless wfid_h.class == Hash 
            next
        end

        proc_durations << wfid_h["duration"]
        
        wfid_h.each do |k, fei_h|
            if k["wfid"].nil?
                next
            end

            name = fei_h["parti_name"]
            if parti_durations[name].nil?
                parti_durations[name] = [fei_h["duration"]]
            else
                parti_durations[name] << fei_h["duration"]
            end 
        end
    end
    [proc_durations, parti_durations]
end

def array_sum_and_aver(arr, prnt = false)
    sum = 0.0
    aver = 0.0
    arr.each do |x|
        sum += x
    end
    aver = sum/arr.length
    
    if prnt
        puts "Run times: #{arr.length}"
        puts "Total:     #{sum}"
        puts "Average:   #{aver}"
    end

    [sum, aver]   
end

# $parti_data format
# {
#   "start"=>"xxx"
#   wfid1=>{
#            "start"=>"xxx"
#            fei1=>{
#                    "parti_name"=>"xxxx"
#                    "start"=>"xxxx"
#                    "end"=>"xxxx"
#                    "duration"=>"xxxx"
#                  }
#            fei2=>{
#                   ......
#                  }      
#            "end"=>"xxx"      
#            "duration"=>"xxxx"
#          }
#   ......        
#   wfidn=>{
#           ......
#          }
#   "end"=>"xxx"
#   "duration"=>"xxx"
# }
def collect_time_data(msgs)
    
    wfid = nil
    h = {} # it's the wfidn harsh part
    start_min = $time_data["start"]
    end_max = $time_data["end"]
    
    msgs.each do |msg|
        case
            when msg["action"] == "launch"
                t = Time.local(*ParseDate.parsedate(msg["put_at"]))
                h["start"] = t
                if t < start_min
                  start_min = t
                end
                wfid = msg["wfid"]

            when msg["action"] == "terminated"
                t = Time.local(*ParseDate.parsedate(msg["put_at"]))
                h["end"] = t
                if t > end_max
                    end_max = t
                end

            when msg["action"] == "dispatch"
                # only set parti_name when "receive" action
                h[msg["fei"]] = {"start" => Time.local(*ParseDate.parsedate(msg["put_at"]))}

            when msg["action"] == "receive"
                fei = msg["fei"]
                
                if h[fei]["start"].nil?
                    puts "Fatal Error: no start time found for #{fei}"
                    exit
                end

                h[fei]["end"] = Time.local(*ParseDate.parsedate(msg["put_at"]))
                h[fei]["parti_name"] = msg["participant_name"]

                h[fei]["duration"] = h[fei]["end"] - h[fei]["start"]
        end
    end

    if h["start"].nil? or h["end"].nil?
        puts "Fatal Error: no start or end time for process #{wfid}"
        exit
    end

    h["duration"] = h["end"] - h["start"]

    $time_data[wfid] = h

    $time_data["start"] = start_min
    $time_data["end"] = end_max
    $time_data["duration"] = end_max - start_min
end


#test here
analyze_time_data(ARGV[0])

puts
puts "++++++++++++ finished +++++++++++++++"
