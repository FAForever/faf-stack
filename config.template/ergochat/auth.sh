#!/bin/sh
read input
wget --header='CONTENT-TYPE:application/json' --post-data "$input" -O - -q $1 && printf '\n' # This assume no endline ohne the API response

#For testing:
#printf '{"success": true, "accountName": "Brutus5000", "error": null}\n'
