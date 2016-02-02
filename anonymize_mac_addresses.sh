#!/bin/bash

function censorMAC {
	echo "Censoring MAC addresses of file $1"
	filename=$(basename "$1")
	echo "saving to $filename"
	sed -r "s/([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}/XX:XX:XX:XX:XX:XX/g" $1 > ./$filename
}


for f in $(find ./uncensored/ -type f ); do
	censorMAC $f
done

echo "The following MAC addresses are still in the dump:"

find ./ -not -path "./uncensored/*" -not -path "./.git/*" -not -type d | xargs grep -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'

echo "end"
