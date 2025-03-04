ANCHOR_IMAGE = "zholme/anchor-unstable:1.7"
def start(plan, index, cl_url, el_rpc, el_ws, key_pem):
    node_name = "anchor-{}".format(index)
    command_arr = [
        "./app", "node", "--network testnet", "--beacon-nodes", cl_url, 
        "--execution-nodes", el_rpc, "--execution-nodes", el_ws, "--datadir data"
    ]

    plan.add_service(
        name=node_name,
        config=ServiceConfig(
            image = ANCHOR_IMAGE,
            entrypoint = command_arr,
            files={
                "/usr/local/bin/data": key_pem
            }
        )
    )

    # node should be running node!

