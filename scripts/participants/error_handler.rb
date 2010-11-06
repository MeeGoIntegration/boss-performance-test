# A logging error handler
class ErrorHandler
  include Ruote::LocalParticipant
  def consume (workitem)
    puts "Error in workitem:"
    puts JSON.pretty_generate workitem.to_h
  end
end

