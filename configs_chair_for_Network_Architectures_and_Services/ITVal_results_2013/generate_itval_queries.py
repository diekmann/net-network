import re
from util import *

    
def main():
    print "starting ..."
    
    classes = readClasses()
    
    ips = []
    for val in classes.itervalues():
        ips.extend(val)
    
    # an ip is a list of tuples, e.g.  [(131, 131), (0, 158), (0, 255), (0, 255)]
    # we have list of ips here
    #print ips
    
    for ip in ips:
        print "QUERY SADDY TO %s AND (FOR TCP 22) AND (IN NEW) AND (ACCEPTED FORWARD);" % (getIPrepresentantString(ip))
    for ip in ips:
        print "QUERY DADDY FROM %s AND (FOR TCP 22) AND (IN NEW) AND (ACCEPTED FORWARD);" % (getIPrepresentantString(ip))

main()
