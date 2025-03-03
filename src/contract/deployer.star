FOUNDRY_SERVICE_NAME = "foundry"

image = ImageBuildSpec(
    image_name="localssv/ssv-network",
    build_context_dir="./",
    build_file="Dockerfile.contract",
    build_args = {
        # Use Kurtosis's built-in UUID generator to bust cache
        "REPO_VERSION": "{{kurtosis.run_uuid}}",  # Unique for every run
    },
)

# deploy all of the contracts
def deploy(plan, el, genesis_constants):
    env_vars = get_env_vars(el, genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key)

    # start the foundry service
    foundry_service = plan.add_service(
        name = FOUNDRY_SERVICE_NAME,
        config = ServiceConfig(
            image=image,
            entrypoint=["tail", "-f", "/dev/null"],
            env_vars = env_vars,
            files = {
                "/app/script/register-operator": plan.upload_files("./registration/RegisterOperators.s.sol"),
                "/app/script/register-validator": plan.upload_files("./registration/RegisterValidators.s.sol")
            }
        )
    )

    # deploy the contracts to the chain and return the contract address
    command_arr = ["forge", "script", "script/DeployAll.s.sol:DeployAll", "--broadcast", "--rpc-url", "${ETH_RPC_URL}", "--private-key", "${PRIVATE_KEY}", "--legacy"]
    out = plan.exec(
        service_name = FOUNDRY_SERVICE_NAME,
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", " ".join(command_arr)]
        )
    )

    # TODO!() get this from the output, 0x6db20C530b3F96CD5ef64Da2b1b931Cb8f264009
    return "0xBFfF570853d97636b78ebf262af953308924D3D8"


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
        "VALIDATORS_PER_OPERATOR_LIMIT": "500",
        "OPERATOR_KEYS_FILE": "/app/operator_keys.json"
    }

