import re



#return one ip address from the range
def getIPrepresentantString(ip):
    assert(type(ip) == type([]))
    assert(len(ip) == 4)
    rep = [low for (low, high) in ip]
    return "%d.%d.%d.%d" % (rep[0], rep[1], rep[2], rep[3])
    
    
    
def parseFromToIP(ip):
    assert(type(ip) == type(""))
    ip = str.split(ip, '.')
    assert(len(ip) == 4)
    result = []
    for i in range(4):
        try:
            result.append((int(ip[i]), int(ip[i])))
        except ValueError:
            byteRegEx = re.compile(r"""\[(\d{1,3})-(\d{1,3})\]""", re.X)
            m = re.match(byteRegEx, ip[i])
            if(m is not None):
                assert(len(m.groups()) == 2)
                frm = int(m.group(1))
                to = int(m.group(2))
            else:
                byteRegEx = re.compile(r"""\[(\d{1,3})\]""", re.X)
                m = re.match(byteRegEx, ip[i])
                assert(len(m.groups()) == 1)
                frm = int(m.group(1))
                to = int(m.group(1))
            #print("from %d to %d" % (frm, to))
            result.append((frm, to))
    return result


# a nicht leere schnittmenge mit b
def ipIsIn(a, b):
    assert(type(a) == type([]))
    assert(type(b) == type([]))
    assert(len(a) == 4)
    assert(len(b) == 4)
    for i in range(4):
        (lowA, highA) = a[i]
        (lowB, highB) = b[i]
        if highA < lowB:
            return False
        if lowA > highB:
            return False
    return True


def ipToStr(a):
    assert(type(a) == type([]))
    assert(len(a) == 4)
    s = ["", "", "", ""]
    for i in range(len(a)):
        (a_1, a_2)  = a[i]
        if a_1 == a_2:
            s[i] = "%s" % a_1
        else:
            s[i] = ("[%s-%s]" % (a_1, a_2))
            
    return "%s.%s.%s.%s" %(s[0], s[1], s[2], s[3])
    


def readClasses():
    classes = dict()
    f = open("successful_classes_query_raw")
    classes_str = ""
    l = f.read()
    l = str.replace(l, '\n', '')
    #print l
    
    ip = r"""(?:(?:\d{1,3}|\[\d{1,3}-\d{1,3}\])\.){3}(?:\d{1,3}|\[\d{1,3}-\d{1,3}\])"""
    ipRegEx = re.compile(ip, re.X)
    
    classRegEx = re.compile(r"""Class\d{1,3}:\s*((?:"""+ip+"""\s*)+)""", re.X)
    m = re.findall(classRegEx, l)
    print "found classes: %d " % len(m)
    for i in range(len(m)):
        ips = re.findall(ipRegEx, m[i])
        classes[i] = ips
        
    #print classes
    for key in classes.iterkeys():
        classes[key] = [parseFromToIP(ip) for ip in classes[key]]
    #print classes
    assert(len(classes.keys()) == len(m))
    return classes

