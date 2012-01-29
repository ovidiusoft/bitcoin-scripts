#!/bin/sh
#
# written by Ovidiu Constantin aka ovidiusoft <ovidiu@mybox.ro>
# imput CSV format: amount,privkey
#

TEMPLATE="designs/papercoins-ovidiusoft.glabels"
FIN="$1"

if [ "$FIN" = "" ]; then
    echo "Usage: $0 <input-file>"
    echo ""
    echo "Input file si a CSV with 'amount,privkey' data on each line"
    exit 1
fi

TMPDIR=`mktemp -d`
TMPCSV=`mktemp XXXXXXXXXX.csv --tmpdir=$TMPDIR`
DATE=`date '+%s'`
PDF="PaperCoins-$DATE.pdf"

while read LINE; do
    KEY=`echo $LINE | cut -f 2 -d ','`
    qrencode -o $TMPDIR/$KEY.png $KEY
    echo "$LINE,$TMPDIR/$KEY.png" >> $TMPCSV
done < $FIN

glabels-batch -C -l -i $TMPCSV -o $PDF $TEMPLATE

rm -rf $TMPDIR
