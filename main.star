ethereum_package = import_module("github.com/ethpandaops/ethereum-package/main.star")
input_parser = import_module("github.com/ethpandaops/ethereum-package/src/package_io/input_parser.star")
genesis_constants = import_module("github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star")
ssv_node = import_module("./nodes/ssv/node.star")
anchor_node = import_module("./nodes/anchor/node.star")
blocks = import_module("./blockchain/blocks.star")
utils = import_module("./utils/utils.star")
deployer = import_module("./contract/deployer.star")
interactions = import_module("./contract/interactions.star")
operator_keygen = import_module("./generators/operator-keygen.star")
validator_keygen = import_module("./generators/validator-keygen.star")
keysplit = import_module("./generators/keysplit.star")
constants = import_module("./utils/constants.star")
monitor = import_module("./monitor/monitor.star")
cluster = import_module("./nodes/cluster.star")

def run(plan, args):
    plan.print("validating input")
    ssv_node_count = args["nodes"]["ssv"]["count"]
    anchor_node_count = args["nodes"]["anchor"]["count"]
    total_nodes = ssv_node_count + anchor_node_count

    if not cluster.is_valid_cluster_size(total_nodes):
        fail("invalid cluster size: ", str(total_nodes))

    plan.print("launching blockchain network")
    blockchain_args = args["network"]
    extra_args = args["extra_params"]
    ethereum_network = ethereum_package.run(plan, blockchain_args)

    plan.print("network launched. Network output: " + json.indent(json.encode(ethereum_network)))
    plan.print("blockchain network is running. Waiting for it to be ready")

    cl_url, el_service_name, el_rpc, el_ws = utils.get_network_attributes(ethereum_network.all_participants)
    blocks.wait_until_node_reached_block(plan, el_service_name, 5)

    plan.print("deploying SSV smart contracts")
    deployer.deploy(plan, el_rpc, genesis_constants)
    plan.print("ACCOUNT PRIVATE KEY: ", genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key)

    unregistered_validators = extra_args["unregistered_validator_count"]
    non_ssv_validators = blockchain_args["participants"][0]["validator_count"] * blockchain_args["participants"][0]["count"]
    total_validators = blockchain_args["network_params"]["preregistered_validator_count"]
    ssv_validators = total_validators - non_ssv_validators - unregistered_validators

    eth_args = input_parser.input_parser(plan, blockchain_args)
    
    # Generate new keystore files
    plan.print("generating validator keystores")
    keystore_files = validator_keygen.generate_validator_keystores(
        plan,
        eth_args.network_params.preregistered_validator_keys_mnemonic,
        non_ssv_validators,
        ssv_validators,
    )

    # ------------------ ADDITIONAL UNREGISTERED VALIDATORS ------------------
    unregistered_start_index = non_ssv_validators + ssv_validators
    plan.print("generating unregistered validator keystores starting from index: " + str(unregistered_start_index))

    # Additional unregistered validators
    unregistered_keystore_files = validator_keygen.generate_validator_keystores(
        plan,
        eth_args.network_params.preregistered_validator_keys_mnemonic,
        unregistered_start_index,
        unregistered_validators,
        register=False,
    )

    plan.print("unregistered keystores generated. Artifact UUID: " + unregistered_keystore_files.files_artifact_uuid)

    plan.print("initializing operator CLI with generated keystores")
    operator_keygen.start_cli(plan, keystore_files)

    plan.print("generating operator keys. Number of keys: " + str(total_nodes))
    public_keys, private_keys, pem_artifacts = operator_keygen.generate_keys(plan, total_nodes)

    # # Once we have all of the keys, register each operator with the network
    plan.print("registering operators to the network")
    operator_data_artifact = interactions.register_operators(plan, public_keys, constants.SSV_NETWORK_PROXY_CONTRACT)

    # # Split the ssv validator keys into into keyshares
    plan.print("splitting validator keys into shares")
    keyshare_artifact = keysplit.split_keys(
        plan,
        keystore_files,
        operator_data_artifact,
        constants.SSV_NETWORK_PROXY_CONTRACT,
        constants.OWNER_ADDRESS,
        el_rpc
    )

    # # Register validators on the network
    plan.print("registering network validators")
    interactions.register_validators(
        plan,
        keyshare_artifact,
        constants.SSV_NETWORK_PROXY_CONTRACT,
        constants.SSV_TOKEN_CONTRACT,
        el_rpc,
        genesis_constants
    )

    node_index = 0
    enr = ""

    if anchor_node_count > 0:
        plan.print("deploying Anchor nodes. Node count: " + str(anchor_node_count))

        # start up all of the anchor nodes
        config = utils.anchor_testnet_artifact(plan)
        enr = anchor_node.start(plan, anchor_node_count, cl_url, el_rpc, el_ws, pem_artifacts, config)

    node_index += anchor_node_count

    plan.print("deploying SSV nodes. Node count: " + str(ssv_node_count))
    ssv_node_api_url = None

    # Start up the ssv nodes
    for _ in range(ssv_node_count):
        is_exporter = False
        config = ssv_node.generate_config(plan, node_index, cl_url, el_ws, private_keys[node_index], enr, is_exporter)
        plan.print("generated SSV node config artifact: " + json.indent(json.encode(config)))

        plan.print("starting SSV node with index: " + str(node_index))
        node_service = ssv_node.start(plan, node_index, config, is_exporter)

        plan.print("ssv node started. Service name: " + node_service.name)

        if ssv_node_api_url == None:
            ssv_node_api_url = node_service.ports[ssv_node.SSV_API_PORT_NAME].url

        node_index += 1

    monitor_enabled = args["monitor"]["enabled"]
    if monitor_enabled:
        if ssv_node_count == 0:
            plan.print("no SSV nodes deployed. Skipping monitor deployment")
            return

        plan.print("launching monitor. SSV node API URL: {}. CL URL: {}".format(ssv_node_api_url, cl_url))
        monitor.start(plan, ssv_node_api_url, cl_url)
