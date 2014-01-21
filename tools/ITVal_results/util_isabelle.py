

def generate_isabelle_file(connectivity_classes, classes, filename): 
    #generate an Isabelle thy file
    
    assert(type(filename) == type(""))
    
    
    
    connectivity_graph = ["""(%d, %d)""" % (src_c, dst_c) for (src_c, dst_c) in connectivity_classes]
    print """ G = (%s, [%s]) """ % (classes.keys(), ", ".join(connectivity_graph))
    
    
    
    f = open(filename, 'w')
    
    f.write("theory i8_ssh_landscape\n")
    f.write("""imports NetworkModel_Library Impl_List_Composition
    Impl_List_StatefulPolicy\n""")
    f.write("begin\n\n")
    
    f.write("""definition I8SSHgraph :: "nat list_graph" where
    "I8SSHgraph \<equiv> \<lparr> nodesL = """ + str(classes.keys()) + """,\n    edgesL = [""")
    f.write(", ".join(connectivity_graph))
    f.write("""] \<rparr>" \n\n\n""")
    
    f.write("""  lemma "valid_list_graph I8SSHgraph" by eval\n\n\n""")
    
    f.write("""definition Confidentiality1::"(nat NetworkSecurityModel)" where
      "Confidentiality1 \<equiv> new_configured_list_NetworkSecurityModel NM_BLPtrusted_impl.NM_LIB_BLPtrusted \<lparr> 
          node_properties = [""")
    nP = ["%d \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>" % k for k in classes.iterkeys()]
    f.write(",\n         ".join(nP))
    f.write("""], 
          model_global_properties = () 
          \<rparr>"\n\n""")
          
          
    f.write("""definition "Subnet1 \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_SubnetsInGW \<lparr> 
          node_properties = [""")
    nP = ["%d \<mapsto> InboundGateway" % k for k in classes.iterkeys()]
    f.write(",\n         ".join(nP))
    f.write("""], 
          model_global_properties = () 
          \<rparr>"\n\n""")
          
    f.write("""definition "Subnet2 \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_SubnetsInGW \<lparr> 
          node_properties = [""")
    nP = ["%d \<mapsto> Member" % k for k in classes.iterkeys()]
    f.write(",\n         ".join(nP))
    f.write("""], 
          model_global_properties = () 
          \<rparr>"\n\n""")
          
    
    f.write("""definition "I8Requirements = [Confidentiality1, Subnet1, Subnet2]"


value[code] "get_offending_flows I8SSHgraph I8Requirements"

lemma "all_security_requirements_fulfilled I8Requirements I8SSHgraph" by eval

lemma "set (filter_IFS_no_violations I8SSHgraph I8Requirements) = set (edgesL I8SSHgraph)" by eval


value[code] "filter_compliant_stateful_ACS I8SSHgraph I8Requirements"

text{*noBiFlows is the list of flows where not already a bidirectional flows is allowed.
      That is, the list of flows we might wish to be stateful to enhance connectivity. *}
definition "noBiFlows = [e \<leftarrow> edgesL I8SSHgraph. case e of (s,r) \<Rightarrow> \<not> ((s,r) \<in> set (edgesL I8SSHgraph) \<and> (r,s) \<in> set (edgesL I8SSHgraph)) ]"
lemma "set noBiFlows = set (filter_compliant_stateful_ACS I8SSHgraph I8Requirements)" by eval

value[code] "generate_valid_stateful_policy_IFSACS I8SSHgraph I8Requirements"

text{*even the order of the list is preserved!!*}
lemma "flows_stateL (generate_valid_stateful_policy_IFSACS I8SSHgraph I8Requirements) = noBiFlows" by eval


lemma "set (flows_stateL (generate_valid_stateful_policy_IFSACS I8SSHgraph I8Requirements)) = set noBiFlows" by eval


\n\n""")

    
    f.write("end")
