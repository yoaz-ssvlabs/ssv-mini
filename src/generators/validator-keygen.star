validator_keystores = import_module("github.com/ethpandaops/ethereum-package/src/prelaunch_data_generator/validator_keystores/validator_keystore_generator.star")

# Generate the validator keystores for the new ssv validators
def generate_validator_keystores(plan, eth_args):
    participants = [
        struct(
            validator_count = 16,
            cl_type = "lighthouse",  
            el_type = "geth"
        )
    ]

    return validator_keystores.generate_validator_keystores(
        plan,
        eth_args.network_params.preregistered_validator_keys_mnemonic,
        participants,
        eth_args.docker_cache_params
    )
