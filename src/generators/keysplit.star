ANCHOR_KEYSPLIT = "anchor-keysplit"
ANCHOR_IMAGE = "zholme/anchor-unstable:latest"

def split_keys(plan, keystores, operator_ids, operator_public_keys, network_address, owner_address):

    # Create a service for running the keysplit operation
    # this needs to have access to the validator keystores, the operator ids, 
    # (could use onchain split to get rid of needed to pass in the rsa keys)??
    plan.add_service(
        name=ANCHOR_KEYSPLIT,
        config=ServiceConfig(
            image=ANCHOR_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            files={
                # Mount the keystores directory
                "/keystores": keystores.files_artifact_uuid,
            },
        )
    )

    # execute the keysplit
    # tood!() should this be a shell script??
    keysplit_cmd = f"/usr/local/bin/app keysplit onchain \
        --keystore-path {keystore_path} \
        --password-file {password_file} \
        --owner {owner_address} \
        --output-path {output_file} \
        --operators {operator_ids_str} \
        --nonce 0"

    # Run the split and then cat the output so that we can get the share data for registering onchain
    result = plan.exec(
        service_name=ANCHOR_KEYSPLIT,
        recipe=ExecRecipe(
            command=["sh", "-c", keysplit_cmd]
        )
    )

    # Read the output file
    cat_cmd = f"cat {output_file}"
    output_result = plan.exec(
        service_name=ANCHOR_KEYSPLIT,
        recipe=ExecRecipe(
            command=["sh", "-c", cat_cmd]
        )
    )
    
    # list of the calldata to be sent to the chain
    split_data = []
    return split_results


