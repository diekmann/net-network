import re
from util import *
from util_isabelle import *
from util_dot import *


def assert_list_set_eq(A, B):
    print "slow set-equal function"
    assert(type(A) == type([]))
    assert(type(B) == type([]))
    assert(type(A) == type(B))
    for a in A:
        assert(a in B)
    for b in B:
        try:
            assert(b in A)
        except:
            print "b not in A: %s not in A" % (b)
            assert(b in A)
    print "the two lists are set-equal"



ip_simple = r"""(?:(?:\d{1,3}|\[\d{1,3}-\d{1,3}\])\.){3}(?:\d{1,3}|\[\d{1,3}-\d{1,3}\])"""
ip_simpleRegEx = re.compile(ip_simple, re.X)

ip_star = r"""(?:(?:\[\d{1,3}\]|\[\d{1,3}-\d{1,3}\]|\*)\.){3}(?:\[\d{1,3}\]|\[\d{1,3}-\d{1,3}\]|\*)"""
ip_starRegEx = re.compile(ip_star, re.X)
    

def read_SADDY(ips_classes, ips_classes_representants):
    print "read_SADDY"
    connectivity = []
    f = open("successful_queries", 'r')
    l = f.readline()
    while (l != ''):
        if l.startswith("QUERY SADDY TO"):
            #dst_ip is one representatn from a class of ips
            dst_ip = re.findall(ip_simpleRegEx, l)[0]
            assert(dst_ip in ips_classes_representants)
            dst_ip = parseFromToIP(dst_ip)
            #get the classes dst_ip is in
            dst_ips = [ip for ip in ips_classes if ipIsIn(dst_ip, ip)]
            assert(len(dst_ips) == 1) # dst_ip uniquely matched to its ip class
            dst_ip = dst_ips[0]
            dst_ips = None
            #print dst_ip
            l = f.readline()
            assert(l.startswith("#"))
            src_ips = re.findall(ip_starRegEx, l)
            src_ips = [ip.replace("*", "[0-255]") for ip in src_ips]
            src_ips = [parseFromToIP(ip) for ip in src_ips]
            #print "%s -> %s" % (src_ips, dst_ip)
            #match src ips to their classes
            tmp = []
            for sip in src_ips:
                src_ips_classes = [ip for ip in ips_classes if ipIsIn(sip, ip)]
                tmp.extend(src_ips_classes)
            src_ips = tmp
            #print "%s -> %s" % (src_ips, dst_ip)
            for sip in src_ips:
                connectivity.append((sip, dst_ip))
            #print "\n"
            
        l = f.readline()
    f.close()
    f = None
    return connectivity

def read_DADDY(ips_classes, ips_classes_representants):
    print "read DADDY"
    connectivity = []
    f = open("successful_queries", 'r')
    l = f.readline()
    while (l != ''):
        if l.startswith("QUERY DADDY FROM"):
            #src_ip is one representatn from a class of ips
            src_ip = re.findall(ip_simpleRegEx, l)[0]
            assert(src_ip in ips_classes_representants)
            src_ip = parseFromToIP(src_ip)
            #get the classes src_ip is in
            src_ips = [ip for ip in ips_classes if ipIsIn(src_ip, ip)]
            assert(len(src_ips) == 1) # src_ip uniquely matched to its ip class
            src_ip = src_ips[0]
            src_ips = None
            #print src_ip
            l = f.readline()
            assert(l.startswith("#"))
            dst_ips = re.findall(ip_starRegEx, l)
            dst_ips = [ip.replace("*", "[0-255]") for ip in dst_ips]
            dst_ips = [parseFromToIP(ip) for ip in dst_ips]
            #print "%s -> %s" % (src_ip, dst_ips)
            #match src ips to their classes
            tmp = []
            for dip in dst_ips:
                dst_ips_classes = [ip for ip in ips_classes if ipIsIn(dip, ip)]
                tmp.extend(dst_ips_classes)
            dst_ips = tmp
            #print "%s -> %s" % (src_ip, dst_ips)
            for dip in dst_ips:
                connectivity.append((src_ip, dip))
            #print "\n"
            
        l = f.readline()
        
    f.close()
    f = None
    return connectivity
        
def getClassByIp(classes, ip):
    assert(type(classes) == type(dict()))
    matches = 0
    result = None
    for k in classes.iterkeys():
        assert(type(classes[k]) == type([]))
        assert(type(classes[k][0]) == type([]))
        assert(len(classes[k][0]) == 4)
        if ip in classes[k]:
            matches += 1
            result = k
    if result is None:
        raise "not Found"
    assert(matches == 1)
    return result

def main():
    print "starting ..."
    
    classes = readClasses()
    
    ips_classes = []
    for val in classes.itervalues():
        ips_classes.extend(val)
    
    ips_classes_representants = [getIPrepresentantString(ip) for ip in ips_classes]
    
    
    
    #read SADDY and DADDY queries, assert that they produce the same result  
    
    if True: #read src addresses, so who can reach this
        connectivity_saddy = read_SADDY(ips_classes, ips_classes_representants)  
        
    
    print "connectivity_classes stats (saddy)"
    connectivity_classes_saddy = [(getClassByIp(classes, src_ip), getClassByIp(classes, dst_ip)) for (src_ip, dst_ip) in connectivity_saddy]
    print "len connectivity_classes_saddy %d" % len(connectivity_classes_saddy)
    connectivity_classes_saddy = list(set(connectivity_classes_saddy))
    print "len connectivity_classes_saddy distinct: %d" % len(connectivity_classes_saddy)
    print "len classes.keys: %d" % len(classes.keys())
    print "end"
    
    connectivity_classes =  []
    connectivity = []
    
    if True: #read dest addresses, so who can this reach
        connectivity = read_DADDY(ips_classes, ips_classes_representants)
    
    
    assert_list_set_eq(connectivity_saddy, connectivity)
    print "SADDY and DADDY result in the same connectivity strucutre"
    
    
    connectivity_str = [(""""%s" -> "%s"\n""" % (ipToStr(src_ip), ipToStr(dst_ip))) for (src_ip, dst_ip) in connectivity]
    #print connectivity_str
    print "connectivity_str stats"
    print len(connectivity_str)
    connectivity_str = list(set(connectivity_str))
    print len(connectivity_str)
    print len(ips_classes)
    
    print "TODO: check that classes really have the same communication relationship"
    
    #print connectivity
    print "connectivity_classes stats"
    connectivity_classes = [(getClassByIp(classes, src_ip), getClassByIp(classes, dst_ip)) for (src_ip, dst_ip) in connectivity]
    print "len connectivity_classes: %d" % len(connectivity_classes)
    connectivity_classes = list(set(connectivity_classes))
    print "len connectivity_classes distinct: %d" % len(connectivity_classes)
    print len(classes.keys())
    
    
    assert(connectivity_classes_saddy == connectivity_classes)
    print "connectivity_classes_saddy == connectivity_classes"
    print """reading "who can this reach to" and "what can reach to this" is the same"""
    
    #print connectivity_classes
    
    gen_dot_file(connectivity_classes, classes)
    
    generate_isabelle_file(connectivity_classes, classes, "i8_ssh_landscape.thy")

    
    
main()
