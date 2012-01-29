#!/usr/bin/env python
#
# quickly check stats on Eligius mining pool
#
# written by Ovidiu Constantin aka ovidiusoft <ovidiu@mybox.ro>

import json, urllib2, datetime

##### BITCOIN

address = '1ATvwns9ZbC2uTjezPwiPJ8qYw9Pag7iMx'
url = 'http://eligius.st/~luke-jr/raw/5/balances.json'
data = json.load(urllib2.urlopen(url, timeout=5))
print "=====[ BITCOIN ]==============================="
print "Address  : " + address
print "Balance  : " + str(data[address]['balance']/100000000.0)
print "Everpaid : " + str(data[address]['everpaid']/100000000.0)
print "Oldest   : " + str(datetime.datetime.fromtimestamp(data[address]['oldest']))
print "Newest   : " + str(datetime.datetime.fromtimestamp(data[address]['newest']))

##### NAMECOIN

address = 'N8gQwLghqu3jPoEVN6rj827hsmqvwtdbTx'
url = 'http://eligius.st/~luke-jr/raw/5/NMC/balances.json'
data = json.load(urllib2.urlopen(url, timeout=5))
print "=====[ NAMECOIN ]=============================="
print "Address  : " + address
print "Balance  : " + str(data[address]['balance']/100000000.0)
print "Everpaid : " + str(data[address]['everpaid']/100000000.0)
print "Oldest   : " + str(datetime.datetime.fromtimestamp(data[address]['oldest']))
print "Newest   : " + str(datetime.datetime.fromtimestamp(data[address]['newest']))
