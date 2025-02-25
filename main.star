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

SSV_NODE_COUNT = 2
ANCHOR_NODE_COUNT = 2

VALIDATORS = 16

VALIDATOR_KEYSTORE_SERVICE = "validator-key-generation-cl-validator-keystore"

def run(plan, args):

    ethereum_network = ethereum_package.run(plan, args)
    eth_args = input_parser.input_parser(plan, args)
    args["network_params"]["preregistered_validator_count"] += VALIDATORS

    plan.remove_service(VALIDATOR_KEYSTORE_SERVICE)

    cl_url, el_rpc, el_ws = utils.get_eth_urls(ethereum_network.all_participants)
    ssv_config_template = read_file(SSV_CONFIG_TEMPLATE_FILEPATH);
    blocks.wait_until_node_reached_block(plan, "el-1-geth-lighthouse", 1)

    # Deploy all of the contracts onto the network
    network_address = deployer.deploy(plan, el_rpc, genesis_constants);


    # Operator generation and deployment
    # ----------------------------------

    # Generate public/private keypair for every operator we are going to deploy
    operator_keygen.start_cli(plan)
    public_keys, private_keys = operator_keygen.generate_keys(plan, SSV_NODE_COUNT + ANCHOR_NODE_COUNT);

    # Once we have all of the keys, register each operator with the network
    interactions.register_operators(plan, public_keys, genesis_constants, network_address, el_rpc)

    # Start up all of the nodes 
    for index in range(0, SSV_NODE_COUNT):
        config = ssv_node.generate_config(plan, index, ssv_config_template, el_ws, cl_url, private_keys[index])
        ssv_node.start(plan, index, config, cl_url, el_rpc, el_ws)

    for index in range(0, ANCHOR_NODE_COUNT):
        plan.print("todo")


    # Validator key generation, key splitting, and deployment
    # ----------------------------------

    keystore_results = validator_keygen.generate_keystores(plan, eth_args)
    split_keys = keysplit.split_keys(plan, eth_args, keystore_results)
    interactions.add_validators(plan, split_keys)

    # The network should be functional here!
