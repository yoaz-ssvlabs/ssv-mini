constants = import_module("../utils/constants.star")

ANCHOR_KEYSPLIT = "anchor-keysplit"

def split_keys(plan, keystores, operator_data_artifact, network_address, owner_address):
    plan.add_service(
        name=ANCHOR_KEYSPLIT,
        config=ServiceConfig(
            image=constants.ANCHOR_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            files={
                "/usr/local/bin/operator_data": operator_data_artifact,
                "/usr/local/bin/keystores": keystores.files_artifact_uuid,
                "/usr/local/bin/keysplit": plan.upload_files("../scripts/keysplit.sh")
            },
            env_vars = {
                "OWNER_ADDRESS": constants.OWNER_ADDRESS
            }
        )
    )

    plan.exec(
        service_name=ANCHOR_KEYSPLIT,
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", "chmod u+x keysplit/keysplit.sh && cd keysplit && ./keysplit.sh"]
        )
    )

    keyshare_artifact = plan.store_service_files(
        service_name = ANCHOR_KEYSPLIT,
        src="/usr/local/bin/keysplit/out.json",
        name="keyshares.json"
    )


    return keyshare_artifact
