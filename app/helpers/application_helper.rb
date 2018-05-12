module ApplicationHelper
  def time_format(time)
    time.in_time_zone('Tokyo').strftime("%Y/%m/%d %-H:%M")
  end
end
