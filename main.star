ethereum_package = import_module("github.com/ethpandaops/ethereum-package/main.star")
validator_keystores = import_module("github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/validator_keystores/validator_keystore_generator.star")
input_parser = import_module("github.com/ethpandaops/ethereum-package/src/package_io/input_parser.star")
genesis_constants = import_module("github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star")
ssv_node = import_module("./src/ssv/ssv-node.star")
blocks = import_module("./src/blockchain/blocks.star")
utils = import_module("./src/utils/utils.star")
deployer = import_module("./src/contract/deployer.star")
keygen  = import_module("./src/ssv/operator-keygen.star")

# Config constants (todo!() can pull these out)
SSV_NODE_COUNT = 2
ANCHOR_NODE_COUNT = 2

VALIDATORS = 16

STATIC_FILES_DIRPATH = "/static_files"

SSV_CONFIG_DIRPATH = "/ssv-config"

SSV_CONFIG_TEMPLATE_FILEPATH = (
        STATIC_FILES_DIRPATH
        + SSV_CONFIG_DIRPATH
        + "/templates/ssv-config.yml.tmpl"
)

def run(plan, args):
    '''
    # Spin up the network 
    ethereum_network = ethereum_package.run(plan, args)
    cl_url, el_rpc, el_ws = utils.get_eth_urls(ethereum_network.all_participants)
    ssv_config_template = read_file(SSV_CONFIG_TEMPLATE_FILEPATH);
    blocks.wait_until_node_reached_block(plan, "el-1-geth-lighthouse", 1)

    # Compile and deploy all of the contracts to the local network
    contracts = deployer.run(plan, "kurtosis", el_rpc, ethereum_network.blockscout_sc_verif_url)
    plan.print(contracts)
    '''

    keygen.start_cli(plan)


    # Operator generation and deployment
    # ----------------------------------

    # Generate public/private keypair for every operator we are going to deploy
    public_keys, private_keys = keygen.generate_keys(plan, SSV_NODE_COUNT + ANCHOR_NODE_COUNT);

    '''
    # Once we have all of the keys, register each operator with the network
    deployer.register_operators(plan, public_keys, genesis_constants, contracts.ssvNetworkAddress, el_rpc)

    # Generate a new config for each node and start them up
    for index in range(0, SSV_NODE_COUNT + ANCHOR_NODE_COUNT):
        config = ssv_node.generate_config(plan, index, ssv_config_template, el_ws, cl_url, private_keys[index])
        plan.print(config)
        ssv_node.start(plan, index, config)


    # Validator generation and deployment
    # ----------------------------------
    '''

