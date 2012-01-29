#!/bin/bash
# Written by Ovidiu Constantin aka ovidiusoft <ovidiu@mybox.ro>
# If you find this script useful, please consider donating to 1DBknUP423BGPQt5Rqg7mr1WLwqdZ8WpPP .
#
# The script will try various overclocking settings and will determine the best combination for the greatest hashrate
#

############################
# CONFIGS

# ID of the card, as reported by aticonfig --list-adapters
CARDID=0

# start, stop and step/increments for GPU frequency
MINGPU=1045
MAXGPU=1050
STEPGPU=5

# start, stop and step/increments for RAM frequency
MINRAM=300
MAXRAM=350
STEPRAM=10

# number of Mhs samples to read
SAMPLES=20
# delay between each sample read (seconds)
SAMPLETIME=3

# critical temperature. If reached, testing stops
MAXTEMP=80

# location and command line to start/stop the miner. Change your user, password and pool address! Take care at the DEVICE=$CARDID argument!
MINERDIR="/home/miner/phoenix-1.50"
STARTMINER="./phoenix.py -u http://username:password@pit.deepbit.net:8332 -q 4 -k phatk VECTORS VECTORS2 BFI_INT FASTLOOP=false AGGRESSION=14 WORKSIZE=256 DEVICE=$CARDID"
KILLMINER="pkill -9 phoenix.py"

# initial delay until the first test starts, to allow the miner to initialize and connect to the pool (seconds)
INITIALDELAY=20

# comment the next two lines after you edit your settings above
echo "PLEASE EDIT YOUR SETTINGS BEFORE RUNNING ME!"
exit 1


############################
# overclock - apply new frequencies to card
# $1 - card ID
# $2 - GPU frequency
# $3 - RAM frequency

overclock()
{
	aticonfig --adapter=$1 --od-enable >/dev/null
	aticonfig --adapter=$1 --odsc=$2,$3 >/dev/null
	aticonfig --adapter=$1 --odcc >/dev/null
}

############################
# wait_and_monitor - sleep X seconds while monitoring temperature and bailing out on overheating
# $1 - time to wait
# $2 - card ID
# $3 - max temperature

wait_and_monitor()
{
	for i in `seq 1 $1`; do
        	TEMP=`aticonfig --adapter=$2 --odgt | tail -n 1 | awk '{ print $5; }' | cut -d '.' -f 1`
                if [ $TEMP -ge $3 ]; then
			echo "!!! WARNING !!! CARD IS OVERHEATING - I AM DOWNCLOCKING IT NOW !!!"
			overclock $2 200 200
			echo "I am also killing the miner and exiting. Sorry about that."
			$KILLMINER
			exit 1
		fi
		sleep 1
	done
}


############################
# MAIN

LOGFILE="/tmp/phoenix.log"
CSVDIR=`pwd`
TIME=`date '+%s'`
CSVFILE="$CSVDIR/results.$TIME"

echo "Starting the miner..."
cd $MINERDIR
$STARTMINER >$LOGFILE &
echo "Sleeping $INITIALDELAY seconds to allow the miner to connect to the pool..."
sleep $INITIALDELAY
echo "Checking that I can read a hashrate from the log..."

HASHRATE=`tail -n 1 $LOGFILE 2>/dev/null | awk '{ print $1; }' | cut -c 2-`
ISNUMBER='^[0-9|.][.0-9]*$'	# not perfect expression, but good enough for us. I stole it somewhere on the Interwebs

if [[ $HASHRATE =~ $ISNUMBER ]]; then
    echo "Hashrate reading is correct, we can start testing..."
else
    echo "I can't get the hashrate from the log. Killing the miner and stopping tests. Sorry."
    $KILLMINER
    exit 1
fi

echo "GPU,RAM,Mhs" > $CSVFILE
BESTGPU=0
BESTRAM=0
BESTHASH=0

echo "Setting fan speed to 100%, just so we don't fry the card..."
aticonfig --adapter=$CARDID --pplib-cmd "set fanspeed 0 100" >/dev/null

GPUF=$MINGPU
while [ $GPUF -le $MAXGPU ]; do
    RAMF=$MINRAM
    while [ $RAMF -le $MAXRAM ]; do
	SUM=0
	echo "================================================================================"
	echo "TEST STARTED | GPU: $GPUF | RAM: $RAMF"
	echo "--------------------------------------------------------------------------------"
	echo "Applying the new values to the card..."
	overclock $CARDID $GPUF $RAMF
	echo "Waiting 5 seconds for hashrate to stabilize after the new settings..."
	wait_and_monitor 5 $CARDID $MAXTEMP
	echo "Gathering $SAMPLES samples, every $SAMPLETIME seconds."
	SAMPLE=1
	while [ $SAMPLE -le $SAMPLES ]; do
		wait_and_monitor $SAMPLETIME $CARDID $MAXTEMP
		HASHRATE=`tail -n 1 $LOGFILE 2>/dev/null | awk '{ print $1; }' | cut -c 2-`
		if [ "$HASHRATE" = "0" ]; then
			echo "Hashrate 0, pool is down? I will wait 5 seconds and then repeat the sample reading."
			wait_and_monitor 5 $CARDID $MAXTEMP
		else
			SUM=`echo $SUM+$HASHRATE | bc`
			echo "Sample: $SAMPLE, $HASHRATE Mhs, $TEMP deg.C."
			SAMPLE=$((SAMPLE+1))
		fi
	done
	AVGHASHRATE=`echo "scale=2 ; $SUM/$SAMPLES" | bc`
	echo "$GPUF,$RAMF,$AVGHASHRATE" >> $CSVFILE
	GT=`echo "$AVGHASHRATE > $BESTHASH" | bc`
	if [ "$GT" = "1" ]; then
		BESTGPU=$GPUF
		BESTRAM=$RAMF
		BESTHASH=$AVGHASHRATE
	fi
	echo "--------------------------------------------------------------------------------"
	echo "TEST COMPLETE | GPU: $GPUF | RAM: $RAMF | RESULT: $AVGHASHRATE Mhs"
	echo "================================================================================"
	echo ""
	echo ""
	RAMF=$((RAMF+STEPRAM))
    done
    GPUF=$((GPUF+STEPGPU))
done

$KILLMINER

echo "Testing is done, miner was stopped! All the results are in $CSVFILE. Here are the best values I detected:"
echo ""
echo "================================================================================"
echo "BEST RESULTS | GPU: $BESTGPU | RAM: $BESTRAM | RESULT: $BESTHASH Mhs"
echo "================================================================================"
echo ""
echo "If you find this script useful, please consider donating to 1DBknUP423BGPQt5Rqg7mr1WLwqdZ8WpPP ."
echo ""
