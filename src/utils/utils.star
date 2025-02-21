def get_eth_urls(all_participants):
    # Use the first consensus layer (CL) and execution layer (EL) nodes
    cl_hostname = "cl-1-lighthouse-geth"
    el_hostname = "el-1-geth-lighthouse"
    
    # Build URLs using standard ports for each service
    cl_uri = "http://{0}:4000".format(cl_hostname)         # Beacon node API
    el_rpc_uri = "http://{0}:8545".format(el_hostname)     # JSON-RPC endpoint
    el_ws_uri = "ws://{0}:8546".format(el_hostname)        # WebSocket endpoint
    
    return (cl_uri, el_rpc_uri, el_ws_uri)

def new_template_and_data(template, template_data_json):
    return struct(template=template, data=template_data_json)
