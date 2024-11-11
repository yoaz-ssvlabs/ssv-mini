ethereum_package = import_module(
    "github.com/ethpandaops/ethereum-package/main.star"
)
genesis_constants = import_module(
    "github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)
validator_keystores = import_module("./src/validators/validator_keystore_generator.star")

utils = import_module("./src/utils/utils.star")
hardhat = import_module("./src/contract//hardhat.star")
# e2m = import_module("./src/e2m/e2m_launcher.star")


def run(plan, args):

    ethereum_network = ethereum_package.run(plan, args)
    cl_url, el_rpc_uri, el_ws_url = utils.get_eth_urls(ethereum_network.all_participants)
    # validator_data = validator_keystores.generate_validator_keystores(
    #     plan, args["network_params"]["preregistered_validator_keys_mnemonic"], 129, 192
    # )
    plan.print("Ethereum network launched successfully")
    plan.print("blockscout ", ethereum_network.blockscout_sc_verif_url)
    plan.print("Ethereum network URL: ", cl_url)
    plan.print("Ethereum network RPC URI: ", el_rpc_uri)
    plan.print("Ethereum network WS URL: ", el_ws_url)

    hardhat.init(plan, el_rpc_uri, ethereum_network.blockscout_sc_verif_url)
    hardhat.compile(plan)
    contract_output = hardhat.deploy(plan)
    plan.print(contract_output)
    hardhat.verify_many(plan, [contract_output.ssvTokenAddress, contract_output.operatorsModAddress, contract_output.clustersModAddress, contract_output.daoModAddress, contract_output.viewsModAddress, contract_output.ssvNetworkAddress])

    # e2m_url = e2m.launch_e2m(plan, cl_url)
    # plan.print("E2M URL: ", e2m_url)
