require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :LinearLayout, :TextView, :ListView

import "android.content.Intent"
import "android.net.Uri"

java_import "org.apache.http.client.methods.HttpGet"
java_import "org.apache.http.impl.client.BasicResponseHandler"
java_import "org.apache.http.impl.client.DefaultHttpClient"

require 'json/pure'

class BrbRubotoMeetupAppActivity

  def on_create(bundle)
    super
    set_title 'Bergen Ruby Brigade'

    self.content_view =
        linear_layout :orientation => :vertical do
          @title_view = text_view :text => 'Bergen Ruby Brigade', :text_size => 32.0
          @meet_header_view = text_view :text => 'Meetups:',      :text_size => 24.0
          @list_view = list_view :list => [],
            :on_item_click_listener => proc {|a,v,p,i| clicked_on_meetup(a,v,p,i) }
          button  :text => 'Find meetups', 
                  :width => :match_parent, 
                  :on_click_listener => proc { show_meetup }
          button  :text => 'BRB Home Page', 
                  :width => :match_parent, 
                  :on_click_listener => proc { show_home_page }
        end
    self.find_meetup_events
  rescue
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end

  def find_meetup_events
    @meet_header_view.text = "(...loading meetups...)"
    @list_view.adapter.clear
    Thread.with_large_stack(128) do

      android.os.Looper.prepare   # Event loop for thread; needed by Exception handler?
      @meetup_api_key ||= get_string(Ruboto::R::string::meetup_api_key)

      # Load from Meetup.
      begin
        url = "https://api.meetup.com/2/events?key=#{@meetup_api_key}&sign=true&group_urlname=bergenrb&status=upcoming,past"
        page = get_remote_page(url)
        parsed_response = JSON.parse(page.to_s)
        events = parsed_response['results'].reverse   # TODO: .sort{|e| e['time'].to_i }
      rescue => err
        puts "Error loading from Meetup: #{err.to_s}"
        run_on_ui_thread { toast "Oisann! Meetup ville ikke leke... \n#{err.to_s}" }
      end

      # Update the UI.
      run_on_ui_thread do
        @list_view.adapter.clear
        events.each {|e| @list_view.adapter.add(e['name']) }   # TODO: .adapter.add_all
        @list_view.invalidate_views
        @meet_header_view.text = "Meetups:"
        @meetup_events = events
      end if events

    end
  end

  def show_meetup
    find_meetup_events
  end

  def clicked_on_meetup(a,v,p,i)
    toast "Viser: #{v.text.to_s}"
    event = @meetup_events[p]
    go_to_url(event['event_url']) if event
  end

  def show_home_page
    go_to_url("http://bergenrb.no/")
  end

  def get_remote_page(url)
    with_large_stack do
      DefaultHttpClient.new.execute(HttpGet.new(url), BasicResponseHandler.new)
    end
  end

  def go_to_url(url)
    intent = Intent.new(Intent::ACTION_VIEW)
    intent.setData(Uri.parse(url))
    startActivity(intent)
  end

end
