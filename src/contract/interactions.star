image = ImageBuildSpec(
    image_name="localssv/ssv-network",
    build_context_dir="./",
    build_file="Dockerfile.contract"
)

def register_operators(plan, public_keys, network_address):
    # Write the keys into the container as json.
    quoted_keys = []
    for key in public_keys:
        quoted_keys.append('"{}"'.format(key))

    json_content = '{{"publicKeys": [{}]}}'.format(", ".join(quoted_keys))
    plan.exec(
        service_name="foundry",
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", "echo '{}' > /app/operator_keys.json".format(json_content)]
        )
    )

    # Now, register all of the operators
    command_arr=[
        "forge", "script", "script/register-operator/RegisterOperators.s.sol:RegisterOperators",
        "--sig", "\'run(address)\'", network_address,
        "--rpc-url", "${ETH_RPC_URL}",
        "--private-key", "${PRIVATE_KEY}",
        "--broadcast", "--legacy" 
    ]

    plan.exec(
        service_name="foundry",
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", " ".join(command_arr)],
        )
    )

    # get a file artifact to the operator data
    operator_data_artifact = plan.store_service_files(
        service_name="foundry",
        src="/app/operator_data.json",
        name="operator_data.json"
    )

    return operator_data_artifact


def register_validators(plan, keyshare_artifact, network_address, owner_address, rpc, genesis_constants):


    # start the foundry service
    foundry_service = plan.add_service(
        name = "register-validator",
        config = ServiceConfig(
            image=image,
            entrypoint=["tail", "-f", "/dev/null"],
            env_vars = {
                "ETH_RPC_URL": rpc,
                "PRIVATE_KEY": genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key,
                "SSV_NETWORK_ADDRESS": network_address
            },
            files = {
                "/app/script/register-validator": plan.upload_files("./registration/RegisterValidators.s.sol"),
                "/app/script/keyshares": keyshare_artifact,
                "/app/script/register": plan.upload_files("./validator-register.sh")
            }
        )
    )

    plan.exec(
        service_name="register-validator",
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", "chmod u+x script/register/validator-register.sh && ./script/register/validator-register.sh "]
        )
    )




