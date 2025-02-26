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

# todo list:
# network address extraction and operator id extraction
# split the validator keys
# register the validators on the network
# start the anchor nodes

SSV_NODE_COUNT = 2
ANCHOR_NODE_COUNT = 2

# These are the ssv specific validators
VALIDATORS = 16

VALIDATOR_KEYSTORE_SERVICE = "validator-key-generation-cl-validator-keystore"

def run(plan, args):
    # Generate the keys for the SSV specific validators
    genesis_validator_count = args["network_params"]["preregistered_validator_count"]

    ethereum_network = ethereum_package.run(plan, args)
    eth_args = input_parser.input_parser(plan, args)

    cl_url, el_rpc, el_ws = utils.get_eth_urls(ethereum_network.all_participants)
    blocks.wait_until_node_reached_block(plan, "el-1-geth-lighthouse", 1)

    # Deploy all of the contracts onto the network
    network_address = deployer.deploy(plan, el_rpc, genesis_constants);


    # Generate new keystore files
    keystore_files =  validator_keygen.generate_validator_keystores(
        plan, 
        eth_args.network_params.preregistered_validator_keys_mnemonic, 
        genesis_validator_count, 
        VALIDATORS
    );

    # Operator generation and deployment
    # ----------------------------------

    # Generate public/private keypair for every operator we are going to deploy
    operator_keygen.start_cli(plan, keystore_files)
    public_keys, private_keys = operator_keygen.generate_keys(plan, SSV_NODE_COUNT + ANCHOR_NODE_COUNT);

    # Once we have all of the keys, register each operator with the network
    interactions.register_operators(plan, public_keys, network_address)

    # Start up the anchor nodes
    for index in range(0, ANCHOR_NODE_COUNT):
        plan.print("todo")



    #keysplit.split_keys(plan, keystore_files)




    # The network should be functional here!!
