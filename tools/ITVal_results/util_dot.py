
from util import *

def gen_dot_file(connectivity_classes, classes):
    connectivity_dot = [""""%s" -> "%s"\n""" % (src_c, dst_c) for (src_c, dst_c) in connectivity_classes]
    
    
    f = open("graph.dot", 'w')
    
    f.write("digraph graphname {\n")
    f.write("overlap=scalexy;\n")
    f.write("splines=true;\n")
    
    f.write(""" node [shape=box]
 node [fontname=Verdana,fontsize=12]
 node [style=filled]
 node [fillcolor="#EEEEEE"]
 node [color="#EEEEEE"]
 edge [color="#31CEF0"]""")
    for k in classes.iterkeys():
        label = """%d[label=<<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">""" % (k)
        label += """<TR><TD CELLPADDING="2"><FONT face="Verdana Bold">Class%d</FONT></TD></TR>""" % (k)
        for ip in classes[k]:
            label += "<TR><TD>%s</TD></TR>" % (ipToStr(ip))
        label += "</TABLE>>]"
        f.write(label + "\n")
    
    for c in connectivity_dot:
        f.write(c)
    
    f.write("}")
    
