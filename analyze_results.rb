#!/usr/bin/env ruby

require 'rubygems'
require 'ruote'
require 'parsedate'

$time_data = {}

def analyze_time_data(path)
    Dir["#{path}/*.msgs"].each do |file|
        #puts "+++++++++ deal with #{file}"
        File.open(file) do |f|
            msgs = Marshal.load(f)
            collect_time_data(msgs)
        end
    end
    statistics_time_data()
    #p $time_data
end

def statistics_time_data()
    proc_durations, parti_durations = collect_durations()
    #p proc_durations
    #p parti_durations
    
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
# }
def collect_time_data(msgs)
    
    wfid = nil
    h = {} # it's the wfidn harsh part
    
    msgs.each do |msg|
        case
            when msg["action"] == "launch"
                h["start"] = Time.local(*ParseDate.parsedate(msg["put_at"]))
                wfid = msg["wfid"]

            when msg["action"] == "terminated"
                h["end"] = Time.local(*ParseDate.parsedate(msg["put_at"]))

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
end


#test here
analyze_time_data(ARGV[0])

puts "++++++++++++ finished +++++++++++++++"
