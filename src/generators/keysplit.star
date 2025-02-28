ANCHOR_KEYSPLIT = "anchor-keysplit"
ANCHOR_IMAGE = "zholme/anchor-unstable:latest"

def split_keys(plan, keystores, operator_data_artifact, network_address, owner_address):
    # Create a service for running the keysplit operation
    # this needs to have access to the validator keystores, the operator ids, 
    # (could use onchain split to get rid of needed to pass in the rsa keys)??
    plan.add_service(
        name=ANCHOR_KEYSPLIT,
        config=ServiceConfig(
            image=ANCHOR_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            files={
                "/operator_data": operator_data_artifact,
                "/keystores": keystores.files_artifact_uuid,
            },
        )
    )


    split_data = []
    return split_data

