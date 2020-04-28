#!/bin/bash
# Set all leaderboard records to inactive, where no game was played in the last 3 months
SCRIPT_BASE_DIR=$(cd "$(dirname "$0")" || exit; cd ../; pwd)
DB_CONFIG_FILE="$SCRIPT_BASE_DIR/config/faf-db/faf-db.env"

echo "Reading db config from $DB_CONFIG_FILE"

# shellcheck source=../config/faf-db/faf-db.env"
source "$DB_CONFIG_FILE"

# Ladder1v1 leaderboard
echo "Processing inactive users for ladder1v1 leaderboard"

docker exec -u root -i faf-db mysql -D "${MYSQL_DATABASE}" <<SQL_SCRIPT
  CREATE TEMPORARY TABLE active_players AS
      (
          SELECT DISTINCT gps.playerId
          FROM game_player_stats gps
          INNER JOIN game_stats gs on gps.gameId = gs.id
          WHERE gs.endTime > now() - INTERVAL 1 YEAR
          AND gs.gameMod = 6
          AND gs.validity = 0
      );

  UPDATE ladder1v1_rating
      LEFT JOIN active_players ON ladder1v1_rating.id = active_players.playerId
  SET is_active = active_players.playerId IS NOT NULL
  WHERE is_active != active_players.playerId IS NOT NULL;

  DROP TABLE active_players;
SQL_SCRIPT

# Global leaderboard
echo "Processing inactive users for global leaderboard"

docker exec -u root -i faf-db mysql -D "${MYSQL_DATABASE}" <<SQL_SCRIPT
  CREATE TEMPORARY TABLE active_players AS
      (
          SELECT DISTINCT gps.playerId
          FROM game_player_stats gps
          INNER JOIN game_stats gs on gps.gameId = gs.id
          WHERE gs.endTime > now() - INTERVAL 1 YEAR
          AND gs.gameMod = 0
          AND gs.validity = 0
      );

  UPDATE global_rating
      LEFT JOIN active_players ON global_rating.id = active_players.playerId
  SET is_active = active_players.playerId IS NOT NULL
  WHERE is_active != active_players.playerId IS NOT NULL;

  DROP TABLE active_players;
SQL_SCRIPT
