# TODO: REPLACE THIS WITH ANCHOR OPERATOR KEYGEN

SSV_NODE_IMAGE = "ssv-node:custom-config"
SSV_CLI_SERVICE_NAME = "ssv-cli"

# Start a new container to interact with the ssv node via cli
def start_cli(plan):
    files = {}
    plan.add_service(
        name=SSV_CLI_SERVICE_NAME,
        config=ServiceConfig(
            image=SSV_NODE_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            files=files,
        ),
    )

# Generate num_keys rsa keypairs
def generate_keys(plan, num_keys):
    operator_public_keys = []
    operator_private_keys = []

    for index in range(0, num_keys):
        keys = generate_operator_keys(plan)
        operator_public_keys.append(keys.public_key)
        operator_private_keys.append(keys.private_key)
    
    return operator_public_keys, operator_private_keys


# Generate a new keypair 
def generate_operator_keys(plan):
    plan.print("generating operator keys")

    plan.exec(
        service_name=SSV_CLI_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh", "-c",
                "/go/bin/ssvnode generate-operator-keys > /tmp/ssv_keys"
            ]
        ),
    )

    public_key = plan.exec(
        service_name=SSV_CLI_SERVICE_NAME,
        recipe=ExecRecipe(command=[
            "/bin/sh", "-c",
            "cat /tmp/ssv_keys | grep 'generated public key' | awk -F'\"' '{print $(NF-1)}' | tr -d ' \n\r'"
        ])
    )["output"]

    private_key = plan.exec(
        service_name=SSV_CLI_SERVICE_NAME,
        recipe=ExecRecipe(command=[
            "/bin/sh", "-c",
            "cat /tmp/ssv_keys | grep 'generated private key' | awk -F'\"' '{print $(NF-1)}' | tr -d ' \n\r'"
        ])
    )["output"]

    return struct(
        public_key=public_key,
        private_key=private_key,
    )
