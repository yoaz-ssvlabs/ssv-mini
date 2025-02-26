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

    # todo!() probs return all of the ids??




def add_validators(plan, split_keys, network_address):
    plan.print("todo: add validators")



