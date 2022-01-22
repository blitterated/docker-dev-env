errcho () {
	echo $@ >&2
}

sleep 3

for i in $(seq 99 0)
do
  errcho "**CRASH!** $i bottles of beer on the wall, $i bottles of beer..."
  sleep 1
done

exit 0
