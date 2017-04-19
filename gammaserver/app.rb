require 'sinatra/base'
require 'sinatra/json'
require 'json'
require 'rubygems'
require 'yaml'
require 'pg'



class GammaApp < Sinatra::Base
  dir = File.dirname(File.expand_path(__FILE__))
  gamma_conf = YAML.load_file("#{dir}/gamma.yaml")

  get '/lastsensordata' do
    # puts gamma_conf
    conn = PGconn.open(
      :host => gamma_conf['gammadb']['host'],
      :port => gamma_conf['gammadb']['port'],
      :options => gamma_conf['gammadb']['options'],
      :tty =>  gamma_conf['gammadb']['tty'],
      :dbname => gamma_conf['gammadb']['dbname'],
      :user => gamma_conf['gammadb']['user'],
      :password => gamma_conf['gammadb']['password']
    )
    #WITH latest_measures AS (SELECT id AS theID, max(ts_device) AS theTS FROM measures GROUP BY id) SELECT * from measures m, latest_measures l WHERE m.id=l.theID AND  m.ts_device=l.theTS

    end_ts = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L%z')
    start_ts = (Time.now - 1*60*60).strftime('%Y-%m-%d %H:%M:%S.%L%z')

    puts "start " + start_ts + ", end " + end_ts

    res= conn.exec(
      "SELECT ts_device, id_device, id_measure, measured_value, max_value, min_value, location, message FROM measures WHERE ts_device > '#{start_ts}' AND ts_device <= '#{end_ts}'")

    # res= conn.exec("WITH latest_measures AS (SELECT id AS theID, max(ts_device) AS theTS FROM  #{gamma_conf['gammadb']['measurestable']} WHERE temp IS NOT NULL GROUP BY id) " +
    #   "SELECT * from  #{gamma_conf['gammadb']['measurestable']} m, #{gamma_conf['gammadb']['sensorparameters']} s, latest_measures l WHERE m.id=l.theID AND  m.ts_device=l.theTS AND s.id=m.id")
    conn.close()
    puts "status " + res.cmd_status().to_s
    puts "tuples " + res.ntuples().to_s
    if res.cmd_tuples() > 0
      msgs = []
      res.each {|tuple|
        msg = build_tuple(tuple)
        puts "hash " + msg.to_s
#        content_type :json
        msgs.push(msg)
      }
      json msgs
    end

  end

  get '/sensordata' do
    # puts gamma_conf

    return_message = {}
    return_message[:status] = 'unknown error'
    return_message[:description] = ""
    return_message[:body] = ""

    puts params

    jdata = JSON.parse(params.to_json,:symbolize_names => true)

    puts jdata

    where_clause = " TRUE "

    if jdata.has_key?(:before)
      where_clause = where_clause + " AND ts_device < '#{jdata[:before]}'"
    end
    if jdata.has_key?(:after)
      where_clause = where_clause + " AND ts_device > '#{jdata[:after]}'"
    end
    if jdata.has_key?(:id_device)
      where_clause = where_clause + " AND id_device = #{jdata[:id_device]}"
    end
    if jdata.has_key?(:id_measure)
      where_clause = where_clause + " AND id_measure = #{jdata[:id_measure]}"
    end
    if jdata.has_key?(:location)
      where_clause = where_clause + " AND location = #{jdata[:location]}"
    end
    if jdata.has_key?(:lower)
      where_clause = where_clause + " AND measured_value >= #{jdata[:lower]}"
    end
    if jdata.has_key?(:upper)
      where_clause = where_clause + " AND measured_value <= #{jdata[:upper]}"
    end

    conn = PGconn.open(
      :host => gamma_conf['gammadb']['host'],
      :port => gamma_conf['gammadb']['port'],
      :options => gamma_conf['gammadb']['options'],
      :tty =>  gamma_conf['gammadb']['tty'],
      :dbname => gamma_conf['gammadb']['dbname'],
      :user => gamma_conf['gammadb']['user'],
      :password => gamma_conf['gammadb']['password']
    )

    query_to_run = "SELECT * FROM measures WHERE #{where_clause}"

    puts "Query to run: #{query_to_run}"

    begin
      res= conn.exec(query_to_run)
    rescue PG::SyntaxError => e
      err_msg = "ERROR: while reading from DB (PG::SyntaxError), error: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = "query: #{query_to_run}"
    rescue PGError => e
      err_msg = "ERROR: while reading from DB, class: #{e.class.name}, message: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = "query: #{query_to_run}"
    ensure
      conn.close()
    end

    if ( return_message[:status] == 'error' )
      return return_message.to_json
    end

    puts "status " + res.cmd_status().to_s
    puts "tuples " + res.ntuples().to_s
    if res.cmd_tuples() > 0
      msgs = []
      res.each {|tuple|
        msg = build_tuple(tuple)
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

  post '/add' do
    params = request.body.read

    jdata = JSON.parse(params,:symbolize_names => true)

    puts jdata

    return_message = {}
    return_message[:status] = 'unknown error'
    return_message[:description] = ""
    return_message[:body] = ""

    if ! jdata.has_key?(:ts_device)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "ts_device "
    end
    if ! jdata.has_key?(:id_device)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "id_device "
    end
    if ! jdata.has_key?(:id_measure)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "id_measure "
    end
    if ! jdata.has_key?(:location)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "location "
    end
    if ! jdata.has_key?(:measured_value)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "measured_value "
    end
    if ! jdata.has_key?(:max_value)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "max_value "
    end
    if ! jdata.has_key?(:min_value)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "min_value "
    end
    if ! jdata.has_key?(:mean_value)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "mean_value "
    end

    if ! jdata.has_key?(:baseline)
      return_message[:status] = 'error'
      return_message[:description] = "Mandatory parameter(s) missing"
      return_message[:body] = return_message[:body] + "baseline "
    end

    if ! jdata.has_key?(:message)
      jdata[:message] = "NULL"
    end



    if ( return_message[:status] == 'error' )
      return return_message.to_json
    end

    conn = PGconn.open(
      :host => gamma_conf['gammadb']['host'],
      :port => gamma_conf['gammadb']['port'],
      :options => gamma_conf['gammadb']['options'],
      :tty =>  gamma_conf['gammadb']['tty'],
      :dbname => gamma_conf['gammadb']['dbname'],
      :user => gamma_conf['gammadb']['user'],
      :password => gamma_conf['gammadb']['password']
    )

    conn.prepare("mypreparedinsert", "INSERT INTO measures (ts_device, id_device, id_measure, measured_value, max_value, min_value, mean_value, baseline, location, message) " +
    "VALUES ($1::timestamp with time zone,$2::bigint,$3::bigint,$4::numeric,$5::numeric,$6::numeric,$7::numeric,$8::numeric,ST_MakePoint($9,$10)::geometry,$11::text)")

    begin
      res= conn.exec_prepared("mypreparedinsert",[jdata[:ts_device], jdata[:id_device], jdata[:id_measure], jdata[:measured_value], jdata[:max_value], jdata[:min_value],
        jdata[:mean_value], jdata[:baseline], jdata[:location][0], jdata[:location][1], jdata[:message]])
    rescue PG::NotNullViolation => e
      err_msg = "ERROR: while inserting message (PG::NotNullViolation), error: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = "received message: #{jdata}"
    rescue PG::UniqueViolation => e
      err_msg = "ERROR: while inserting message (PG::UniqueViolation), error: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = "received message: #{jdata}"
    rescue PG::InvalidTextRepresentation => e
      err_msg = "ERROR: while inserting message (PG::InvalidTextRepresentation), error: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = "received message: #{jdata}"
    rescue PG::CharacterNotInRepertoire => e
      err_msg = "ERROR: wrong encoding (PG::CharacterNotInRepertoire), error: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = "received message: #{jdata}"
    rescue PGError => e
      err_msg = "ERROR: while inserting into DB, class: #{e.class.name}, message: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = "received message: #{jdata}"
    ensure
      conn.close()
    end

    if ( return_message[:status] == 'error' )
      return return_message.to_json
    end

    # res= conn.exec("WITH latest_measures AS (SELECT id AS theID, max(ts_device) AS theTS FROM  #{gamma_conf['gammadb']['measurestable']} WHERE temp IS NOT NULL GROUP BY id) " +
    #   "SELECT * from  #{gamma_conf['gammadb']['measurestable']} m, #{gamma_conf['gammadb']['sensorparameters']} s, latest_measures l WHERE m.id=l.theID AND  m.ts_device=l.theTS AND s.id=m.id")
    puts "status " + res.cmd_status().to_s
    puts "tuples " + res.ntuples().to_s

    return_message[:status] = 'success'
    return_message[:description] = "Status: #{res.cmd_status().to_s}, tuples: #{res.ntuples().to_s}"
    return return_message.to_json

  end

  private

  def build_tuple(tuple)
    return {
      :ts_device => tuple["ts_device"],
      :id_device => tuple["id_device"],
      :id_measure => tuple["id_measure"],
      :measured_value => tuple["measured_value"],
      :max_value => tuple["max_value"],
      :min_value => tuple["min_value"],
      :mean_value => tuple["mean_value"],
      :baseline => tuple["baseline"],
      :location => tuple["location"],
      :message => tuple["message"],
    }

  end

end
