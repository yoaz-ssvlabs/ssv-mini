ethereum_package = import_module(
    "github.com/ethpandaops/ethereum-package/main.star"
)
validator_keystores = import_module(
    "github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/validator_keystores/validator_keystore_generator.star"
)
input_parser = import_module("github.com/ethpandaops/ethereum-package/src/package_io/input_parser.star")
genesis_constants = import_module(
    "github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)
ssv_node = import_module("./src/ssv/ssv-node.star")
static_files = import_module("./src/static_files/static_files.star")
blocks = import_module("./src/blockchain/blocks.star")
# validator_keystores = import_module("./src/validators/validator_keystore_generator.star")

utils = import_module("./src/utils/utils.star")
deployer = import_module("./src/contract/deployer.star")
# e2m = import_module("./src/e2m/e2m_launcher.star")
ssv = import_module("./src/ssv/ssv.star")

SSV_NODE_COUNT = 2
ANCHOR_NODE_COUNT = 2

VALIDATORS = 16

def run(plan, args):
    args["network_params"]["preregistered_validator_count"] += VALIDATORS
    ethereum_network = ethereum_package.run(plan, args)
    eth_args = input_parser.input_parser(args)
    cl_url, el_rpc_uri, el_ws_url = utils.get_eth_urls(ethereum_network.all_participants)
    # validator_data = validator_keystores.generate_validator_keystores(
    #     plan, args["network_params"]["preregistered_validator_keys_mnemonic"], 129, 192
    # )
    plan.print("Ethereum network launched successfully")

    blocks.wait_until_node_reached_block(plan, "el-1-geth-lighthouse", 1)

    contracts = deployer.run(plan, "devnet", el_rpc_uri, ethereum_network.blockscout_sc_verif_url)
    plan.print(contracts)

    # e2m_url = e2m.launch_e2m(plan, cl_url)
    # plan.print("E2M URL: ", e2m_url)

    ssv.start_cli(plan)

    operator_public_keys = []
    operator_private_keys = []
    # operator_configs = []
    for index in range(0, SSV_NODE_COUNT + ANCHOR_NODE_COUNT):
        keys = ssv.generate_operator_keys(plan)
        plan.print("keys")
        plan.print(keys)

        private_key = keys.private_key
        plan.print("private_key")
        plan.print(private_key)

        public_key = keys.public_key
        plan.print("public_key")
        plan.print(public_key)

        # operator_configs.append(ssv.generate_config(plan, el_ws_url, cl_url, private_key))
        operator_public_keys.append(public_key)
        operator_private_keys.append(private_key)

    deployer.register_operators(plan, operator_public_keys, genesis_constants, contracts.ssvNetworkAddress,
                                el_rpc_uri)

    validator_data = validator_keystores.generate_validator_keystores(
        plan,
        eth_args.network_params.preregistered_validator_keys_mnemonic,
        [struct(
            validator_count = VALIDATORS,
            cl_type = "ssv_dummy",
            el_type = "ssv_dummy",
        )],
        eth_args.docker_cache_params,
    )[0]

    plan.print("Starting {} SSV nodes with unique configurations".format(SSV_NODE_COUNT))

    ssv_config_template = read_file(
        static_files.SSV_CONFIG_TEMPLATE_FILEPATH
    )

    for index in range(0, SSV_NODE_COUNT + ANCHOR_NODE_COUNT):
        config = ssv_node.generate_config(plan, index, ssv_config_template, cl_url, el_ws_url, operator_private_keys[index])
        plan.print(config)

        node_service = ssv_node.start(plan, index, config)
        plan.print("Started SSV Node {}".format(index))

    #for index in range(0, ANCHOR_NODE_COUNT):
    #    config = ssv_node.generate_config(plan, index, ssv_config_template, cl_url, el_ws_url, operator_private_keys[index])
    #    plan.print(config)
    #
    #    node_service = ssv_node.start(plan, index, config)
    #    plan.print("Started Anchor Node {}".format(index))
