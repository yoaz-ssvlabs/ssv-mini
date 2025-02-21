ANCHOR_IMAGE = "zholme/anchor-unstable"
ANCHOR_SERIVCE_NAME "anchor"

# Start a new container to interact with the ssv node via cli
def start_cli(plan):
    files = {}
    plan.add_service(
        name=ANCHOR_SERIVCE_NAME,
        config=ServiceConfig(
            image=ANCHOR_IMAGE,
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

    # Execute the anchor keygen command and capture its output
    result = plan.exec(
        service_name = ANCHOR_CLI_SERVICE_NAME,
        recipe = ExecRecipe(
            command = ["/usr/local/bin/app", "keygen"],
            # Ensure we get clean output
            environment = {
                "RUST_LOG": "info"
            }
        ),
    )

    # We can extract the keys reliably by looking for the exact log pattern
    output_lines = result["output"].split("\n")
    public_key = ""
    private_key = ""

    for line in output_lines:
        # Process only non-empty lines
        if line.strip():
            if "INFO keygen: Public:" in line:
                public_key = line.split("Public:")[1].strip()
            elif "INFO keygen: Private:" in line:
                private_key = line.split("Private:")[1].strip()

    # Verify we got both keys
    if not public_key or not private_key:
        fail("Failed to generate or extract keys properly")

    return struct(
        public_key = public_key,
        private_key = private_key,
    )

