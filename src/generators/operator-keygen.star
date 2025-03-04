ANCHOR_IMAGE = "zholme/anchor-unstable:1.4"
ANCHOR_CLI_SERVICE_NAME = "anchor"

def start_cli(plan, keystores):
    plan.add_service(
        name=ANCHOR_CLI_SERVICE_NAME,
        config=ServiceConfig(
            image=ANCHOR_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            files={
                "/keystores": keystores.files_artifact_uuid,
            },
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
    # Execute the anchor keygen command
    result = plan.exec(
        service_name=ANCHOR_CLI_SERVICE_NAME,
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", "/usr/local/bin/app keygen --output-path keys.json && cat keys.json"],
            extract = {
                "public": "fromjson | .public",
                "private": "fromjson | .private",
            }
        ),
    )

    return struct(
        public_key=result["extract.public"],
        private_key=result["extract.private"],
    )
