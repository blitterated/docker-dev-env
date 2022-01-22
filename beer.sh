errcho () {
	echo $@ >&2
}

sleep 3

for i in $(seq -s ' ' $BOTTLES 0)
do
  case "$i" in
    1) NUM_BOTTLES="1 bottle" ;;
    0) NUM_BOTTLES="No more bottles" ;;
    *) NUM_BOTTLES="$i bottles" ;;
  esac

  errcho "**CRASH!** $NUM_BOTTLES of beer on the wall, $NUM_BOTTLES of beer..."
  sleep 1
done

exit 0
