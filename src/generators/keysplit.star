ANCHOR_KEYSPLIT = "anchor-keysplit"
ANCHOR_IMAGE = "zholme/anchor-unstable:latest"

def split_keys(plan, keystores, operator_data_artifact, network_address, owner_address):
    # Create a service for running the keysplit operation
    # this needs to have access to the validator keystores, the operator ids, 
    # start the foundry service
    # (could use onchain split to get rid of needed to pass in the rsa keys)??
    plan.add_service(
        name=ANCHOR_KEYSPLIT,
        config=ServiceConfig(
            image=ANCHOR_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            files={
                "/usr/local/bin/operator_data": operator_data_artifact,
                "/usr/local/bin/keystores": keystores.files_artifact_uuid,
                "/usr/local/bin/keysplit": plan.upload_files("./keysplit.sh")
            },
        )
    )


    # need some shell script to run everything


    split_data = []
    return split_data

