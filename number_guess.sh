#!/bin/bash

echo "Enter your username:"
read -r username

PSQL="psql --username=freecodecamp --dbname=number_guess -q -t --no-align -c"
sql_username=$(printf "%s" "$username" | sed "s/'/''/g")
user_data=$($PSQL "SELECT user_id, (SELECT COUNT(*) FROM games WHERE user_id = users.user_id), COALESCE((SELECT MIN(number_of_guesses) FROM games WHERE user_id = users.user_id), 0) FROM users WHERE username = '$sql_username';")

if [[ -n "$user_data" ]]; then
  IFS='|' read -r user_id games_played best_game <<< "$user_data"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
else
  user_id=$($PSQL "INSERT INTO users (username) VALUES ('$sql_username') RETURNING user_id;")
  echo "Welcome, $username! It looks like this is your first time here."
fi

secret_number=$((RANDOM % 1000 + 1))
guess_count=0

echo "Guess the secret number between 1 and 1000:"
while true; do
  read -r guess || exit 1

  if [[ ! "$guess" =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ "$guess" == -* ]]; then
    guess_value=$((-10#${guess#-}))
  else
    guess_value=$((10#$guess))
  fi
  ((guess_count += 1))

  if ((guess_value < secret_number)); then
    echo "It's higher than that, guess again:"
  elif ((guess_value > secret_number)); then
    echo "It's lower than that, guess again:"
  else
    $PSQL "INSERT INTO games (user_id, number_of_guesses) VALUES ($user_id, $guess_count);"
    echo "You guessed it in $guess_count tries. The secret number was $secret_number. Nice job!"
    break
  fi
done
