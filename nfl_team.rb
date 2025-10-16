#! /usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'date'
require 'optparse'
require 'ostruct'

# Handles team name resolution to ESPN abbreviations
class TeamResolver
  TEAM_ABBR_MAP = {
    # NFC North
    'bears' => 'CHI', 'chicago bears' => 'CHI', 'chicago' => 'CHI', 'chi' => 'CHI',
    'packers' => 'GB', 'green bay packers' => 'GB', 'green bay' => 'GB', 'gb' => 'GB',
    'lions' => 'DET', 'detroit lions' => 'DET', 'detroit' => 'DET', 'det' => 'DET',
    'vikings' => 'MIN', 'minnesota vikings' => 'MIN', 'minnesota' => 'MIN', 'min' => 'MIN',

    # NFC East
    'cowboys' => 'DAL', 'dallas cowboys' => 'DAL', 'dallas' => 'DAL', 'dal' => 'DAL',
    'giants' => 'NYG', 'new york giants' => 'NYG', 'nyg' => 'NYG',
    'eagles' => 'PHI', 'philadelphia eagles' => 'PHI', 'philadelphia' => 'PHI', 'phi' => 'PHI',
    'commanders' => 'WAS', 'washington commanders' => 'WAS', 'washington' => 'WAS', 'was' => 'WAS', 'wsh' => 'WAS',

    # NFC South
    'buccaneers' => 'TB', 'bucs' => 'TB', 'tampa bay buccaneers' => 'TB', 'tampa bay' => 'TB', 'tb' => 'TB',
    'saints' => 'NO', 'new orleans saints' => 'NO', 'new orleans' => 'NO', 'no' => 'NO', 'nor' => 'NO',
    'falcons' => 'ATL', 'atlanta falcons' => 'ATL', 'atlanta' => 'ATL', 'atl' => 'ATL',
    'panthers' => 'CAR', 'carolina panthers' => 'CAR', 'carolina' => 'CAR', 'car' => 'CAR',

    # NFC West
    '49ers' => 'SF', 'niners' => 'SF', 'san francisco 49ers' => 'SF', 'san francisco' => 'SF', 'sf' => 'SF', 'sfo' => 'SF',
    'seahawks' => 'SEA', 'seattle seahawks' => 'SEA', 'seattle' => 'SEA', 'sea' => 'SEA',
    'rams' => 'LAR', 'los angeles rams' => 'LAR', 'la rams' => 'LAR', 'lar' => 'LAR',
    'cardinals' => 'ARI', 'arizona cardinals' => 'ARI', 'arizona' => 'ARI', 'ari' => 'ARI',

    # AFC North
    'ravens' => 'BAL', 'baltimore ravens' => 'BAL', 'baltimore' => 'BAL', 'bal' => 'BAL',
    'bengals' => 'CIN', 'cincinnati bengals' => 'CIN', 'cincinnati' => 'CIN', 'cin' => 'CIN',
    'browns' => 'CLE', 'cleveland browns' => 'CLE', 'cleveland' => 'CLE', 'cle' => 'CLE',
    'steelers' => 'PIT', 'pittsburgh steelers' => 'PIT', 'pittsburgh' => 'PIT', 'pit' => 'PIT',

    # AFC East
    'bills' => 'BUF', 'buffalo bills' => 'BUF', 'buffalo' => 'BUF', 'buf' => 'BUF',
    'dolphins' => 'MIA', 'miami dolphins' => 'MIA', 'miami' => 'MIA', 'mia' => 'MIA',
    'patriots' => 'NE', 'new england patriots' => 'NE', 'new england' => 'NE', 'ne' => 'NE', 'nwe' => 'NE',
    'jets' => 'NYJ', 'new york jets' => 'NYJ', 'nyj' => 'NYJ',

    # AFC South
    'colts' => 'IND', 'indianapolis colts' => 'IND', 'indianapolis' => 'IND', 'ind' => 'IND',
    'jaguars' => 'JAX', 'jags' => 'JAX', 'jacksonville jaguars' => 'JAX', 'jacksonville' => 'JAX', 'jax' => 'JAX',
    'titans' => 'TEN', 'tennessee titans' => 'TEN', 'tennessee' => 'TEN', 'ten' => 'TEN',
    'texans' => 'HOU', 'houston texans' => 'HOU', 'houston' => 'HOU', 'hou' => 'HOU',

    # AFC West
    'chiefs' => 'KC', 'kansas city chiefs' => 'KC', 'kansas city' => 'KC', 'kc' => 'KC', 'kan' => 'KC',
    'raiders' => 'LV', 'las vegas raiders' => 'LV', 'vegas raiders' => 'LV', 'las vegas' => 'LV', 'lv' => 'LV', 'oakland raiders' => 'LV',
    'chargers' => 'LAC', 'los angeles chargers' => 'LAC', 'la chargers' => 'LAC', 'lac' => 'LAC', 'san diego chargers' => 'LAC',
    'broncos' => 'DEN', 'denver broncos' => 'DEN', 'denver' => 'DEN', 'den' => 'DEN'
  }.freeze

  def self.resolve(input)
    return nil if input.nil?
    
    key = input.strip.downcase
    abbr = TEAM_ABBR_MAP[key]
    return abbr if abbr

    # Try normalizations
    key_without_the = key.gsub(/^the\s+/, '')
    return TEAM_ABBR_MAP[key_without_the] if TEAM_ABBR_MAP[key_without_the]

    # Handle special cases
    return 'SF' if key_without_the == '49er'

    nil
  end
end

# Handles ESPN API interactions
class ESPNClient
  BASE_URL = "http://site.api.espn.com/apis/site/v2/sports/football/nfl/teams"
  
  def initialize(team_abbr)
    @team_abbr = team_abbr
  end

  def fetch_schedule
    uri = URI("#{BASE_URL}/#{@team_abbr.downcase}/schedule")
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Error fetching data: #{response.code} - #{response.message}"
    end
  end
end

# Extracts and formats game information
class GameFinder
  LOGO_INDEX = 1
  FINAL_STATUS_NAMES = ['STATUS_FINAL', 'Final'].freeze

  def initialize(team_abbr)
    @team_abbr = team_abbr
    @current_date = DateTime.now
  end

  def find_last_game(response)
    games = filter_games(response, :completed)
    games.max_by { |g| g[:date] }&.dig(:game)
  end

  def find_next_game(response)
    games = filter_games(response, :upcoming)
    games.min_by { |g| g[:date] }&.dig(:game)
  end

  private

  def filter_games(response, type)
    return [] unless response['events']

    games = []
    response['events'].each do |event|
      competition = extract_competition(event)
      next unless competition && team_in_game?(competition)

      game_date = DateTime.parse(event['date'])
      next unless matches_filter_type?(competition, game_date, type)

      games << { game: build_game_info(event, competition), date: game_date }
    end
    games
  end

  def extract_competition(event)
    event.dig('competitions', 0) if event['competitions']&.any?
  end

  def team_in_game?(competition)
    return false unless competition['competitors']

    competition['competitors'].any? do |competitor|
      competitor.dig('team', 'abbreviation')&.casecmp?(@team_abbr)
    end
  end

  def matches_filter_type?(competition, game_date, type)
    case type
    when :completed
      game_date < @current_date && game_completed?(competition)
    when :upcoming
      game_date > @current_date
    else
      false
    end
  end

  def game_completed?(competition)
    status_name = competition.dig('status', 'type', 'name')
    status_desc = competition.dig('status', 'type', 'description')
    FINAL_STATUS_NAMES.include?(status_name) || FINAL_STATUS_NAMES.include?(status_desc)
  end

  def build_game_info(event, competition)
    est_date = DateTime.parse(event['date']).new_offset('-04:00')
    
    {
      'name' => event['name'],
      'date' => event['date'],
      'formatted_date' => est_date.strftime('%A, %B %d, %Y at %I:%M %p EST'),
      'status' => competition.dig('status', 'type', 'description') || 'Scheduled',
      'venue' => competition.dig('venue', 'fullName') || 'TBD',
      'teams' => extract_teams_info(competition)
    }
  end

  def extract_teams_info(competition)
    competition['competitors'].map do |comp|
      {
        'name' => comp.dig('team', 'displayName'),
        'abbreviation' => comp.dig('team', 'abbreviation'),
        'home_away' => comp['homeAway'],
        'score' => comp['score'] || '0',
        'winner' => comp['winner'] || false,
        'record' => extract_record(comp),
        'logo' => extract_logo(comp)
      }
    end
  end

  def extract_record(competitor)
    return 'N/A' unless competitor['record']
    
    competitor['record'].find { |r| r['type'] == 'total' }&.dig('displayValue') || 'N/A'
  end

  def extract_logo(competitor)
    logos = competitor.dig('team', 'logos')
    logos && logos.any? && logos[LOGO_INDEX] ? logos[LOGO_INDEX]['href'] : nil
  end
end

# Publishes data to TRMNL webhook
class TRMNLPublisher
  def initialize(plugin_id)
    @uri = URI.parse("https://usetrmnl.com/api/custom_plugins/#{plugin_id}")
  end

  def publish(data)
    Net::HTTP.start(
      @uri.host,
      @uri.port,
      use_ssl: @uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
      cert_store: OpenSSL::X509::Store.new.tap { |s| s.set_default_paths }
    ) do |http|
      request = Net::HTTP::Post.new(@uri.request_uri, 'Content-Type' => 'application/json')
      request.body = data.to_json
      response = http.request(request)
      
      puts "Response Code: #{response.code}"
      #puts "Response Body: #{response.body}"
    end
  end
end

# Main script execution
def parse_options
  options = OpenStruct.new

  OptionParser.new do |opts|
    opts.banner = "Usage: nfl_team.rb [options]"
    opts.on("-t", "--team TEAM", "Team name or abbreviation (e.g., 'Bears' or 'CHI')") do |team|
      options.team = team
    end
    opts.on("-p", "--plugin-id PLUGIN_ID", "Plugin ID for the TRMNL Plugin") do |plugin_id|
      options.plugin_id = plugin_id
    end
    opts.on("-h", "--help", "Display this help message") do
      puts opts
      exit
    end
  end.parse!

  options
end

def validate_options(options)
  if options.team.nil?
    puts "Please specify a team with --team"
    exit 1
  end

  resolved_abbr = TeamResolver.resolve(options.team)
  if resolved_abbr.nil?
    puts "Could not resolve team '#{options.team}'. Try a nickname (e.g., 'Bears') or a standard abbreviation (e.g., 'CHI')."
    exit 1
  end

  resolved_abbr
end

# Main execution
begin
  options = parse_options
  team_abbr = validate_options(options)

  puts "Getting data for Team: #{options.team} (resolved: #{team_abbr})"

  client = ESPNClient.new(team_abbr)
  response = client.fetch_schedule

  finder = GameFinder.new(team_abbr)
  last_game = finder.find_last_game(response)
  next_game = finder.find_next_game(response)

  result = {
    "merge_variables": {
      "last_game" => last_game,
      "next_game" => next_game
    }
  }


  if options.plugin_id
    publisher = TRMNLPublisher.new(options.plugin_id)
    publisher.publish(result)
  else
    puts "No plugin ID provided. Skipping webhook publication."
  end

rescue StandardError => e
  puts JSON.pretty_generate({ "error" => e.message })
  exit 1
end
