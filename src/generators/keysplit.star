
ANCHOR_CLI_SERVICE_NAME = "anchor"
ANCHOR_IMAGE = "zholme/anchor-unstable:latest"

def split_keys(plan, keystores):
  # Add a service that uses the generated files artifact
    keystore_container_config = ServiceConfig(
        image="alpine:latest",
        files={
            # Mount the artifact to /keystores in container
            "/keystores": keystores.files_artifact_uuid,
            "/ranges": "validator-ranges",
        },
        entrypoint=["tail", "-f", "/dev/null"],  # Keep container running
    )
    plan.add_service("keystore-container", keystore_container_config)

    # Print confirmation message
    plan.print("Successfully stored keystores in container at: /keystores")
    plan.print("Artifact UUID: {}".format(keystores.files_artifact_uuid))





