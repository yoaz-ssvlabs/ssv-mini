# HardHat has problems with node 20 so we use an older version of node
HARDHAT_SERVICE_NAME = "hardhat"
FOUNDRY_SERVICE_NAME = "foundry"

image = ImageBuildSpec(
    image_name="localssv/ssv-network",
    build_context_dir="./",
    build_file="Dockerfile.contract"
)


def run(plan, el, genesis_constants):
    env_vars = get_env_vars(el, genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key)

    # start the foundry service
    foundry_service = plan.add_service(
        name = FOUNDRY_SERVICE_NAME,
        config = ServiceConfig(
            image=image,
            entrypoint=["tail", "-f", "/dev/null"],
            env_vars = env_vars
        )
    )

    deploy(plan)


# deploy all of the contracts
def deploy(plan):
    command_arr = ["forge", "script", "script/DeployAll.s.sol:DeployAll", "--broadcast", "--rpc-url", "${ETH_RPC_URL}", "--private-key", "${PRIVATE_KEY}", "--legacy", "-vvv"]

    out = plan.exec(
        service_name = FOUNDRY_SERVICE_NAME,
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", " ".join(command_arr)]
        )
    )
    plan.print(out)



# set the environment variables for contract deployment
def get_env_vars(eth1_url, private_key):
    return {
        "ETH_RPC_URL": eth1_url,
        "PRIVATE_KEY": private_key,
        "MINIMUM_BLOCKS_BEFORE_LIQUIDATION": "100800",
        "MINIMUM_LIQUIDATION_COLLATERAL": "200000000",
        "OPERATOR_MAX_FEE_INCREASE": "3",
        "DECLARE_OPERATOR_FEE_PERIOD": "259200",  # 3 days
        "EXECUTE_OPERATOR_FEE_PERIOD": "345600",  # 4 days
        "VALIDATORS_PER_OPERATOR_LIMIT": "500"
    }

