require 'sinatra/base'
require 'sinatra/json'
require 'json'
require 'rubygems'
require 'yaml'
require 'pg'



class GammaApp < Sinatra::Base

  attr_accessor :gamma_conf

  def initialize
    dir = File.dirname(File.expand_path(__FILE__))
    @gamma_conf = YAML.load_file("#{dir}/gamma.yaml")
  end

  before do
      content_type 'application/json'
  end

  get '/lastsensordata' do
    return_message = init_retmess(true)

    # puts gamma_conf
    conn = makeDBConnection(return_message)

    if ( return_message[:status] == 'error' )
      return return_message.to_json
    end

    # end_ts = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L%z')
    # start_ts = (Time.now - 1*60*60).strftime('%Y-%m-%d %H:%M:%S.%L%z')
    #
    # puts "start " + start_ts + ", end " + end_ts
    #
    # query_to_run = "SELECT ts_device, id_device, id_measure, measured_value, max_value, min_value, location, message FROM measures WHERE ts_device > '#{start_ts}' AND ts_device <= '#{end_ts}'"

    query_to_run = "SELECT ts_device, id_device, id_measure, measured_value, max_value, min_value, location, message FROM measures LIMIT 50"

    res = nil

    begin

      res= conn.exec(query_to_run)

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

    read_tuples(res,return_message)

    return return_message.to_json

  end

  get '/sensordata' do
    # puts gamma_conf

    return_message = init_retmess(true)

    puts params

    #  Get hash with symbols
    jdata = params.map { |k, v| [k.to_sym, v] }.to_h

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
    if jdata.has_key?(:location) && jdata.has_key?(:radius)
      lat_log = jdata[:location].tr('[]','').split(',')
      where_clause = where_clause + " AND ST_DWithin(location, ST_MakePoint(#{lat_log[0]},#{lat_log[1]}), #{jdata[:radius]});"
    end
    if jdata.has_key?(:lower)
      where_clause = where_clause + " AND measured_value >= #{jdata[:lower]}"
    end
    if jdata.has_key?(:upper)
      where_clause = where_clause + " AND measured_value <= #{jdata[:upper]}"
    end

    conn = makeDBConnection(return_message)

    if ( return_message[:status] == 'error' )
      return return_message.to_json
    end

    query_to_run = "SELECT * FROM measures WHERE #{where_clause}"

    puts "Query to run: #{query_to_run}"

    res = nil
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

    read_tuples(res,return_message)

    return return_message.to_json

  end

  get '/' do
    return_message = {}
    return_message[:status] = 'success'
    return_message[:description] = 'Endpoint up'
    return_message[:body] = ''
    return return_message.to_json
  end

  post '/add' do
    return_message = init_retmess(true)

    params = request.body.read

    jdata = JSON.parse(params,:symbolize_names => true)

    puts jdata

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

    if ( return_message[:status] == 'error' )
      return return_message.to_json
    end

    if ! jdata.has_key?(:message)
      jdata[:message] = "NULL"
    end

    conn = makeDBConnection(return_message)

    if ( return_message[:status] == 'error' )
      return return_message.to_json
    end

    conn.prepare("mypreparedinsert", "INSERT INTO measures (ts_device, id_device, id_measure, measured_value, max_value, min_value, mean_value, baseline, location, message) " +
    "VALUES ($1::timestamp with time zone,$2::bigint,$3::bigint,$4::numeric,$5::numeric,$6::numeric,$7::numeric,$8::numeric,ST_MakePoint($9,$10)::geography ,$11::text)")

    res = nil

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
    return_message[:description] = "Data inserted"
    return_message[:body] = "Status: #{res.cmd_status().to_s}, tuples: #{res.ntuples().to_s}"

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

  def makeDBConnection(return_message)

    conn = nil
    begin
      conn = PGconn.open(
        :host => @gamma_conf['gammadb']['host'],
        :port => @gamma_conf['gammadb']['port'],
        :options => @gamma_conf['gammadb']['options'],
        :tty =>  @gamma_conf['gammadb']['tty'],
        :dbname => @gamma_conf['gammadb']['dbname'],
        :user => @gamma_conf['gammadb']['user'],
        :password => @gamma_conf['gammadb']['password']
      )

      return_message[:status] = 'success'
      return_message[:description] = ''
      return_message[:body] = ''

      puts "Connection to DB successfull #{return_message.to_json}"

    rescue PGError => e
      err_msg = "ERROR: while connecting to Postgres server, class: #{e.class.name}, message: #{e.message}"
      $stderr.puts err_msg
      return_message[:status] = 'error'
      return_message[:description] = err_msg
      return_message[:body] = ''
    end
    return conn
  end

  def init_retmess(isSuccessfull)
    return_message = {}
    if isSuccessfull
      return_message[:status] = 'success'
      return_message[:description] = 'No operation performed'
      return_message[:body] = ''
    else
      return_message[:status] = 'error'
      return_message[:description] = 'Unknown error'
      return_message[:body] = ''
    end

    return return_message
  end

  def read_tuples(res,return_message)

    if res.nil?
      return_message[:status] = 'error'
      return_message[:description] = 'Invalid reference to data'
      return_message[:body] = ''
      return
    end

    puts "status " + res.cmd_status().to_s
    puts "tuples " + res.ntuples().to_s

    msgs = []
    if res.cmd_tuples() > 0
      res.each {|tuple|
        msg = build_tuple(tuple)
        puts "hash " + msg.to_s
#        content_type :json
        msgs.push(msg)
      }
    end

    return_message[:status] = 'success'
    return_message[:description] = "Data retrieved, status: #{res.cmd_status().to_s}, tuples: #{res.ntuples().to_s}"
    return_message[:body] = msgs.to_json

  end

end
