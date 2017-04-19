require 'sinatra/base'
require 'sinatra/json'
require 'json'
require 'rubygems'
require 'yaml'
require 'pg'



class GammaApp < Sinatra::Base
  dir = File.dirname(File.expand_path(__FILE__))
  ms_conf = YAML.load_file("#{dir}/gamma.yaml")

  get '/lastsensordata' do
    puts ms_conf
    conn = PGconn.open(
      :host => ms_conf['gammadb']['host'],
      :port => ms_conf['gammadb']['port'],
      :options => ms_conf['gammadb']['options'],
      :tty =>  ms_conf['gammadb']['tty'],
      :dbname => ms_conf['gammadb']['dbname'],
      :user => ms_conf['gammadb']['user'],
      :password => ms_conf['gammadb']['password']
    )
    #WITH latest_measures AS (SELECT id AS theID, max(srv_ts) AS theTS FROM measures GROUP BY id) SELECT * from measures m, latest_measures l WHERE m.id=l.theID AND  m.srv_ts=l.theTS

    end_ts = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L%z')
    start_ts = (Time.now - 1*60*60).strftime('%Y-%m-%d %H:%M:%S.%L%z')

    puts "start " + start_ts + ", end " + end_ts

    res= conn.exec(
      "SELECT srv_ts, id_device, id_measure, value, max_value, min_value, location, message FROM measures WHERE srv_ts > '#{start_ts}' AND srv_ts <= '#{end_ts}")

    # res= conn.exec("WITH latest_measures AS (SELECT id AS theID, max(srv_ts) AS theTS FROM  #{ms_conf['gammadb']['measurestable']} WHERE temp IS NOT NULL GROUP BY id) " +
    #   "SELECT * from  #{ms_conf['gammadb']['measurestable']} m, #{ms_conf['gammadb']['sensorparameters']} s, latest_measures l WHERE m.id=l.theID AND  m.srv_ts=l.theTS AND s.id=m.id")
    conn.close()
    puts "status " + res.cmd_status().to_s
    puts "tuples " + res.ntuples().to_s
    if res.cmd_tuples() > 0
      msgs = []
      res.each {|tuple|
        msg = {
          :srv_ts => tuple["srv_ts"],
          :id_device => tuple["id_device"],
          :id_measure => tuple["id_measure"],
          :value => tuple["value"],
          :max_value => tuple["max_value"],
          :min_value => tuple["min_value"],
          :location => tuple["location"],
          :message => tuple["message"],
        }
        puts "hash " + msg.to_s
#        content_type :json
        msgs.push(msg)
      }
      json msgs
    end

  end

  get '/' do
    json :alive => 'yes'
  end
end
