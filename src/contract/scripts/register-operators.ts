// Define imports
const hre = require("hardhat");
const { ethers } = hre;

export type InteractContract = {
    environment: string
    contractAddress: string
    account: Account
    eth1URL: string
    tokenAddress: string
    amount?: string
    operatorPublicKeys?: string[]
    operators?: {
        id: number;
        publicKey: string;
    }[]
    operatorId?: number
    path?: string
    validator?: string
    validatorsToAdd?: number
    setPrivate?: boolean
}

export type CallContract = {
    eth1URL: string
    contractAddress: string
    contractFactory: string
    privateKey: string
}

export async function connectContract(contractParams: CallContract) {
    // Build provider on the needed network
    const provider = ethers.getDefaultProvider(contractParams.eth1URL)

    // Build wallets from the private keys
    let account = new ethers.Wallet(contractParams.privateKey, provider)
    console.log(`Wallet Address: ${account.address}`);

    // Attach SSV Network
    const ssvNetworkFactory = await ethers.getContractFactory(contractParams.contractFactory)

    // Return success message
    return { contract: ssvNetworkFactory.attach(contractParams.contractAddress), account }
}

export async function registerOperators() {
    console.log("env dump")
    console.log("ethers.getSigners()", await ethers.getSigners())
    console.log("SSV_NETWORK_ADDRESS_STAGE", process.env.SSV_NETWORK_ADDRESS_STAGE)
    console.log("OWNER_PRIVATE_KEY", process.env.OWNER_PRIVATE_KEY)
    console.log("SSV_NODE_COUNT", process.env.SSV_NODE_COUNT)
    console.log("RPC_URI", process.env.RPC_URI)

    const operatorParams: InteractContract = {
        amount: '1000000000', // TODO: set correctly
        operators: [
            {
                id: 1, // TODO: pass
                publicKey: process.env.OPERATOR_1_PUBLIC_KEY,
            },
            {
                id: 2,
                publicKey: process.env.OPERATOR_2_PUBLIC_KEY,
            },
            {
                id: 3,
                publicKey: process.env.OPERATOR_3_PUBLIC_KEY,
            },
            {
                id: 4,
                publicKey: process.env.OPERATOR_4_PUBLIC_KEY,
            },
        ],
        eth1URL: process.env.RPC_URI,
        contractAddress: process.env.SSV_NETWORK_ADDRESS_STAGE,
        account: process.env.OWNER_PRIVATE_KEY,
        privateKey: `0x${process.env.OWNER_PRIVATE_KEY}`,
        setPrivate: false,
    }

    console.log('Preparing to register operators')

    // Return if params are undefined
    if (operatorParams.amount === undefined) {
        return { error: true, data: 'Undefined Param', details: `❌ Undefined Param - Amount: ${operatorParams.operators}` }
    }

    // Define registered operator count
    let registeredOperators = 1

    // Attach SSV Network
    const connectedContract = await connectContract({
        eth1URL: operatorParams.eth1URL,
        contractAddress: operatorParams.contractAddress,
        contractFactory: 'SSVNetwork',
        privateKey: operatorParams.account
    })


    // Connect the account to use for contract interaction
    const ssvNetworkContract = await connectedContract.contract.connect(connectedContract.account)

    const owner = await ssvNetworkContract.owner();
    console.log(`Contract Owner: ${owner}`);

    const updateMaximumOperatorFeeResults = await ssvNetworkContract.updateMaximumOperatorFee('76528650000000');
    console.log(`updateMaximumOperatorFee result: ${JSON.stringify(updateMaximumOperatorFeeResults)}`);

    // Log the tx hash
    console.log(`updateMaximumOperatorFee TX Hash: ${updateMaximumOperatorFeeResults.hash}`);

    // Wait for register operator call
    await updateMaximumOperatorFeeResults.wait()

    console.log(`✅ Successfully updated maximum operator fee`)

    // Loop through all public keys to register
    for (let i = 0; i < operatorParams.operators.length; i++) {
        // ABI encode the public key
        const abiCoder = new ethers.AbiCoder()
        const abiEncoded = abiCoder.encode(["string"], [operatorParams.operators[i].publicKey])

        // Log params
        console.log('------------------------ Register Operator -----------------------');
        console.log(`Index: ${i}`)
        console.log(`Public Key: ${operatorParams.operators[i].publicKey}`)
        console.log(`ABI Encoded: ${abiEncoded}`)
        console.log(`Operator Count: ${registeredOperators} out of ${operatorParams.operators.length}`)
        console.log(`Amount: ${operatorParams.amount}`)
        console.log(`Set As Private: ${operatorParams.setPrivate}`)
        console.log('------------------------------------------------------------------');


        try {
            // Register the operator
            const registerOperatorResults = await ssvNetworkContract.registerOperator(
                abiEncoded,
                operatorParams.amount, // '956600000000' <- 2.5 per year - TODO make last 8 num to be 0 in amount and actually divide by blocks per year
                operatorParams.setPrivate
            );

            // Log the tx hash
            console.log(`register operator TX Hash: ${registerOperatorResults.hash}`);

            // Wait for register operator call
            await registerOperatorResults.wait()

            // Log successful registration
            console.log(`✅ Successfully registered operator with public key ${operatorParams.operators[i].publicKey}`)
            registeredOperators++

        } catch (error) {
            if (error.code === 'CALL_EXCEPTION') {
                console.error('Transaction reverted:', JSON.stringify(error));
                return { error: true, data: error, details: `❌ Failed to register operator with public key ${operatorParams.operators[i].publicKey}` };
            }

            // Return error if needed
            console.log(`ERROR ${error}`)

            return { error: true, data: error, details: `❌ Failed to register operator with public key ${operatorParams.operators[i].publicKey}` }
        }
    }
    // Return success message
    return { error: false, data: `Registered ${registeredOperators} operators`, details: `Successfully registered ${registeredOperators} operators` }
}

registerOperators()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
