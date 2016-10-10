#!/usr/bin/env zsh

MATCHES_FILE=$1

PLAYERS_FILE=players.json

TMP=`mktemp match.XXXX`

ruby parse_data.rb $MATCHES_FILE > $TMP
ruby parse_players.rb $TMP $PLAYERS_FILE
ruby update_r.rb $TMP $PLAYERS_FILE

rm -rf $TMP
