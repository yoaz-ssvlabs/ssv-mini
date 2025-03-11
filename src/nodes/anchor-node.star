constants = import_module("../utils/constants.star")

# Start an anchor node
def start(plan, index, cl_url, el_rpc, el_ws, key_pem, config):
    command_arr = [
        "./anchor", "node", "--testnet-dir testnet", "--beacon-nodes", cl_url, 
        "--execution-nodes", el_rpc, "--execution-nodes", el_ws, "--datadir data"
    ]

    name = "anchor-node-{}".format(index)
    plan.add_service(
        name = name,
        config=ServiceConfig(
            image = constants.ANCHOR_IMAGE,
            cmd=["/bin/sh", "-c", " ".join(command_arr)],
            files={
                "/usr/local/bin/data": key_pem,
                "/usr/local/bin/testnet": config
            },
        )
    )
