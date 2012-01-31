#!/bin/bash
#
# papercoins.sh - written by Ovidiu Constantin aka ovidiusoft <ovidiu@mybox.ro>
#

# PaperCoins template to use
TEMPLATE="designs/papercoins-ovidiusoft.glabels"

# full path to a patched Electrum client, electrum-nic (non-interactive create); copy the patched electrum-nic to your standard Electrum folder
ELECTRUM="/home/user/programs/electrum/electrum-nic"

# wallet to send BTC from
MYWALLET="/home/user/.electrum/electrum.dat"

# THIS IS IMPORTANT! 'mktx' will only create the tx and print it on the screen. 'payto' will broadcast the tx to the network!
OP="mktx"
# OP="payto"

comment the next two lines after you edit the settings above
echo "PLEASE EDIT YOUR SETTINGS BEFORE RUNNING ME!"
exit 1

###############################

D=`date '+%s'`
NEWWALLET="PaperCoins-$D.wallet"
PDF="PaperCoins-$D.pdf"

# get total number of coins and validate that they are numbers
N=0
TOTAL=0
VALUE[1]=""

if [ "$1" = "" ]; then
    echo "Usage: $0 <value> [<value> ...]"
    exit 0
fi

while [ ! "$1" = "" ]; do
    N=$((N+1))
    VALUE[$N]="$1"
    R=`echo "scale=8; ${VALUE[N]} + 1 - 1" | bc`
    if [ "$R" = "0" ]; then
	echo "Not a number: ${VALUE[N]}. This is fatal, exiting."
	exit 1
    fi
    TOTAL=`echo "scale=8; $TOTAL + ${VALUE[N]}" | bc`
    shift
done
echo "Will create $N PaperCoins, with values of ${VALUE[@]} for a total of $TOTAL BTC."

# check there are enough coins in the default wallet for all of them
BALANCE=`$ELECTRUM -w $MYWALLET balance`
echo "Electrum wallet balance: $BALANCE"

R=`echo "$TOTAL" '<' "$BALANCE" | bc`
if [ "$R" = "0" ]; then
    echo "Wallet balance is not sufficient. This is fatal, exiting."
    exit 1
fi

# genereate new Electrum temp wallet with correct number of addresses (gap)
echo "Creating new wallet (default values, $N addresses): $NEWWALLET"
$ELECTRUM -w $NEWWALLET create $N

# dump addresses and keys from new wallet
# for each of them:
#	qrencode private key to png file
#	create csv line with: value,privatekey,qrfile.png
#	generate tx from regular wallet to the public key

echo "Funding the PaperCoins."
TMPDIR=`mktemp -d`
TMPCSV=`mktemp XXXXXXXXXX.csv --tmpdir=$TMPDIR`

N=0
while read LINE; do
    N=$((N+1))
    ADDRESS=`echo $LINE | cut -f 1 -d ':'`
    PRIVKEY=`echo $LINE | cut -f 2 -d ':'`
    qrencode -o $TMPDIR/$ADDRESS.png $PRIVKEY
    echo "${VALUE[N]},$PRIVKEY,$TMPDIR/$ADDRESS.png" >> $TMPCSV

    echo "===[ Transaction to fund PaperCoin #$N (${VALUE[N]} BTC, address $ADDRESS) ]==="
    $ELECTRUM -w $MYWALLET $OP $ADDRESS ${VALUE[N]}
done < <( $ELECTRUM -w $NEWWALLET -k addresses )

echo "========================================================================="

# generate the PDF
echo "Generating the PDF to print your PaperCoins."
glabels-batch -C -l -i $TMPCSV -o $PDF $TEMPLATE
rm -rf $TMPDIR

echo ""
echo "Created: $NEWWALLET"
echo "Created: $PDF"
echo ""
