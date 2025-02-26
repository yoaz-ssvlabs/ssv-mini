def register_operators(plan, public_keys, network_address):
    # Write json formatted keys into the container
    quoted_keys = []
    for key in public_keys:
        quoted_keys.append('"{}"'.format(key))

    # Then create the JSON string using the quoted keys
    json_content = '{{"publicKeys": [{}]}}'.format(", ".join(quoted_keys))

    # Now use this in your exec command
    plan.exec(
        service_name="foundry",
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", "echo '{}' > /app/operator_keys.json".format(json_content)]
        )
    )
    # Run the registration script
    command_arr=[
        "forge", "script", "script/register/RegisterOperators.s.sol:RegisterOperators",
        "--sig", "\'run(address)\'", network_address,
        "--rpc-url", "${ETH_RPC_URL}",
        "--private-key", "${PRIVATE_KEY}",
        "--broadcast", "--legacy"
    ]
    out = plan.exec(
        service_name="foundry",
        recipe=ExecRecipe(
            command = ["/bin/sh", "-c", " ".join(command_arr)]
            
        )
    )


def add_validators(plan, split_keys):
    plan.print("todo: add validators")



