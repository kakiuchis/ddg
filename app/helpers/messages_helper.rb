module MessagesHelper
  def new_or_not(message)
  	if Time.now - message.uptake_time < 3600
  	  p "1時間以内に取り込まれたメール"
  	else
  	  p ""
  	end
  end
  def time_format(time)
  	time.in_time_zone('Tokyo').strftime("%Y/%m/%d %-H:%M")
  end
end
