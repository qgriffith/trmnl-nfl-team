# NFL Team Schedule Tracker

A Ruby script that fetches NFL team schedule information from ESPN's API and optionally publishes it to TRMNL webhooks for display on e-ink devices.

## Features

- 📅 Fetches the last completed game and next upcoming game for any NFL team
- 🏈 Supports all 32 NFL teams with flexible name resolution (nicknames, city names, or abbreviations)
- 🔗 Optional integration with TRMNL custom plugins for e-ink display
- 📊 Provides detailed game information including scores, venues, dates, and team records
- 🖼️ Includes team logos in the output data

## Requirements

- Ruby 3.4.5 or higher
- Bundler 2.6.9

### Dependencies

All dependencies are built into Ruby's standard library:
- `net/http` - HTTP client
- `json` - JSON parsing
- `uri` - URI handling
- `date` - Date/time manipulation
- `optparse` - Command-line argument parsing
- `ostruct` - OpenStruct data structures

## Installation

1. Clone this repository:
```shell script
git clone <repository-url>
cd nfl_scores
```


2. Install dependencies:
```shell script
bundle install
```


3. Make the script executable (optional):
```shell script
chmod +x nfl_team.rb
```


## Usage

### Basic Usage

Get schedule information for a team:

```shell script
ruby nfl_team.rb --team "Chicago Bears"
```


You can use various team identifiers:
```shell script
ruby nfl_team.rb --team "Bears"      # Nickname
ruby nfl_team.rb --team "Chicago"    # City name
ruby nfl_team.rb --team "CHI"        # Abbreviation
```


### TRMNL Integration

To publish data to a TRMNL webhook:

```shell script
ruby nfl_team.rb --team "Bears" --plugin-id YOUR_PLUGIN_ID
```


### Command-Line Options

- `-t, --team TEAM` - Team name or abbreviation (required)
- `-p, --plugin-id PLUGIN_ID` - TRMNL plugin ID for webhook publishing (optional)
- `-h, --help` - Display help message

## Output Format

The script outputs JSON with the following structure:

```json
{
  "merge_variables": {
    "last_game": {
      "name": "Chicago Bears at Detroit Lions",
      "date": "2024-01-07T13:00:00Z",
      "formatted_date": "Sunday, January 07, 2024 at 01:00 PM EST",
      "status": "Final",
      "venue": "Ford Field",
      "teams": [
        {
          "name": "Chicago Bears",
          "abbreviation": "CHI",
          "home_away": "away",
          "score": "17",
          "winner": false,
          "record": "7-10",
          "logo": "https://..."
        }
      ]
    },
    "next_game": {
      // Same structure as last_game
    }
  }
}
```


## Supported Teams

All 32 NFL teams are supported across all divisions:

**NFC North:** Bears, Packers, Lions, Vikings  
**NFC East:** Cowboys, Giants, Eagles, Commanders  
**NFC South:** Buccaneers, Saints, Falcons, Panthers  
**NFC West:** 49ers, Seahawks, Rams, Cardinals  
**AFC North:** Ravens, Bengals, Browns, Steelers  
**AFC East:** Bills, Dolphins, Patriots, Jets  
**AFC South:** Colts, Jaguars, Titans, Texans  
**AFC West:** Chiefs, Raiders, Chargers, Broncos

## Architecture

The script is organized into five main classes:

- **TeamResolver** - Maps various team name inputs to ESPN abbreviations
- **ESPNClient** - Handles API requests to ESPN
- **GameFinder** - Filters and extracts game information
- **TRMNLPublisher** - Publishes data to TRMNL webhooks
- **Main Script** - Orchestrates the workflow and handles command-line interface

## Error Handling

The script includes error handling for:
- Invalid team names
- API connection failures
- Missing required parameters
- Malformed API responses

Errors are output in JSON format for easy parsing.

## License
MIT 
## Author

Quenten Griffiths - [Website](https://quentengriffiths.com) - [GitHub](https://github.com/quentengriffiths)