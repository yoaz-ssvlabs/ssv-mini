constants = import_module("../utils/constants.star")

def start(plan, index, cl_url, el_rpc, el_ws, key_pem):
    node_name = "anchor-{}".format(index)
    command_arr = [
        "./anchor", "node", "--testnet-dir testnet", "--beacon-nodes", cl_url, 
        "--execution-nodes", el_rpc, "--execution-nodes", el_ws, "--datadir data"
    ]

    # add the anchor service and start the node
    plan.add_service(
        name=node_name,
        config=ServiceConfig(
            image = constants.ANCHOR_IMAGE,
            files={
                "/usr/local/bin/data": key_pem
            },
            # Run the command as the service's entrypoint:
            cmd=["/bin/sh", "-c", " ".join(command_arr)]
        )
    )


    # node should be running node!

