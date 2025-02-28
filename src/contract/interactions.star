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
        "--broadcast", "--legacy", "--silent", 
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


def register_validators(plan, split_keys_data, network_address, owner_address, operator_ids):
    plan.print("Registering validators")
    '''
    # Generate the operator IDs assignment code
    operator_ids_assignment = ""
    for i, op_id in enumerate(operator_ids):
        operator_ids_assignment += f"operatorIds[{i}] = {op_id};\n    "
    
    # Replace the placeholder
    register_validator_script = register_validator_script.replace(
        "{operator_ids_assignment}", 
        operator_ids_assignment
    )
    
    # Create the script file in the foundry container
    plan.exec(
        service_name="foundry",
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", f"echo '{register_validator_script}' > /app/script/RegisterValidator.s.sol"]
        )
    )
    
    plan.print("Created validator registration script")
    '''

