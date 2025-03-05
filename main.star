ethereum_package = import_module("github.com/ethpandaops/ethereum-package/main.star")
input_parser = import_module("github.com/ethpandaops/ethereum-package/src/package_io/input_parser.star")
genesis_constants = import_module("github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star")
ssv_node = import_module("./src/nodes/ssv-node.star")
anchor_node = import_module("./src/nodes/anchor-node.star")
blocks = import_module("./src/blockchain/blocks.star")
utils = import_module("./src/utils/utils.star")
deployer = import_module("./src/contract/deployer.star")
interactions = import_module("./src/contract/interactions.star")
operator_keygen = import_module("./src/generators/operator-keygen.star")
validator_keygen = import_module("./src/generators/validator-keygen.star")
keysplit = import_module("./src/generators/keysplit.star")
constants = import_module("./src/utils/constants.star")

def run(plan, args):
    # Start up the chain
    ethereum_network = ethereum_package.run(plan, args)
    eth_args = input_parser.input_parser(plan, args)

    cl_url, el_rpc, el_ws = utils.get_eth_urls(ethereum_network.all_participants)
    blocks.wait_until_node_reached_block(plan, "el-1-geth-lighthouse", 1)

    # Deploy all of the contracts onto the network
    deployer.deploy(plan, el_rpc, genesis_constants);

    # Generate new keystore files
    keystore_files =  validator_keygen.generate_validator_keystores(
        plan, 
        eth_args.network_params.preregistered_validator_keys_mnemonic, 
        args["network_params"]["preregistered_validator_count"], 
        constants.VALIDATORS
    );

    # Generate public/private keypair for every operator we are going to deploy
    operator_keygen.start_cli(plan, keystore_files)
    public_keys, private_keys, pem_artifacts = operator_keygen.generate_keys(plan, constants.SSV_NODE_COUNT + constants.ANCHOR_NODE_COUNT);
    plan.print(pem_artifacts)

    # Once we have all of the keys, register each operator with the network
    operator_data_artifact = interactions.register_operators(plan, public_keys, constants.SSV_NETWORK_PROXY_CONTRACT)

    # Start up the anchor nodes
    for index in range(0, constants.ANCHOR_NODE_COUNT):
        anchor_node.start(plan, index, cl_url, el_rpc, el_ws, pem_artifacts[index])

    # Start up the ssv nodes
    for index in range(0, constants.SSV_NODE_COUNT):
        config = ssv_node.generate_config(plan, index, cl_url, el_ws, private_keys[index])
        node_service = ssv_node.start(plan, index, config)


    # Split the ssv validator keys into into keyshares
    keyshare_artifact = keysplit.split_keys(
        plan, 
        keystore_files, 
        operator_data_artifact,
        constants.SSV_NETWORK_PROXY_CONTRACT, 
        constants.OWNER_ADDRESS
    )

    # Register validators on the network
    interactions.register_validators(
        plan,
        keyshare_artifact,
        constants.SSV_NETWORK_PROXY_CONTRACT, 
        constants.SSV_TOKEN_CONTRACT,
        el_rpc,
        genesis_constants
    )
    # The network should be functional here!
