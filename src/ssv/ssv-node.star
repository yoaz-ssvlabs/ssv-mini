shared_utils = import_module("../utils/utils.star")

# Config constants
SSV_CONFIG_DIR_PATH_ON_SERVICE = "/ssv-config"
CUSTOM_NETWORK_NAME = "local-network"
GENESIS_DOMAIN_TYPE = "0x00000501"
ALAN_DOMAIN_TYPE = "0x00000502"
REGISTRY_SYNC_OFFSET = "181612"
REGISTRY_CONTRACT_ADDR = "0x38A4794cCEd47d3baf7370CcC43B560D3a1beEFA"
LOG_LEVEL = "debug"


# Generat ethe configuration for the node
def generate_config(
        plan,
        index,
        ssv_config_template,
        execution_client,
        consensus_client,
        operator_private_key,
):
    db_path = "./data/db/{}/".format(index)
    file_name = "ssv-config-{}.yaml".format(index)

    # Ensure URLs have correct protocol prefixes and no trailing slashes
    beacon_url = consensus_client.rstrip("/")
    execution_url = execution_client.rstrip("/")

    # Log the URLs we're using for debugging
    plan.print("Beacon node URL: " +  beacon_url)
    plan.print("Execution client URL: " + execution_url)

    # Prepare data for the template
    data = struct(
        LogLevel=LOG_LEVEL,
        DBPath=db_path,
        BeaconNodeAddr=beacon_url,
        ETH1Addr=execution_url,
        CustomNetworkName=CUSTOM_NETWORK_NAME,
        GenesisDomainType=GENESIS_DOMAIN_TYPE,
        AlanDomainType=ALAN_DOMAIN_TYPE,
        RegistrySyncOffset=REGISTRY_SYNC_OFFSET,
        RegistryContractAddr=REGISTRY_CONTRACT_ADDR,
        OperatorPrivateKey=operator_private_key,
    )

    # Render the template into a file artifact
    rendered_artifact = plan.render_templates(
        {
            file_name: shared_utils.new_template_and_data(ssv_config_template, data),
        },
        name=file_name,
    )

    return rendered_artifact


# Start the node
def start(plan, index, config_artifact):
    service_name = "ssv-node-{}".format(index)
    image = "ssv-node:custom-config"  # Matches the new Docker image name
    config_path = "{}/ssv-config-{}.yaml".format(SSV_CONFIG_DIR_PATH_ON_SERVICE, index)

    # Minimal service configuration
    service_config = ServiceConfig(
        image=image,
        entrypoint=[
            "/go/bin/ssvnode",
            "start-node",
            "--config={}".format(config_path),
        ],
        cmd=[],
        env_vars={},
        files={
            SSV_CONFIG_DIR_PATH_ON_SERVICE: config_artifact,  # Map the configuration artifact to the desired path
        },
    )

    # Add the service
    plan.add_service(service_name, service_config)

    # Return the service object
    return plan.get_service(service_name)
