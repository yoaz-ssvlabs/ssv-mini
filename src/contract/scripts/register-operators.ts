const hre = require("hardhat");
const { ethers } = hre;

interface Operator {
    id: number;
    publicKey: string;
}

async function connectContract(
    eth1URL: string,
    contractAddress: string,
    contractFactory: string,
    privateKey: string
) {
    const provider = new ethers.JsonRpcProvider(eth1URL);

    const wallet = new ethers.Wallet(privateKey, provider);
    console.log(`Connected Wallet Address: ${wallet.address}`);

    const factory = await ethers.getContractFactory(contractFactory, wallet);
    const contract = factory.attach(contractAddress);

    return contract;
}

async function updateMaximumOperatorFee(contract: ethers.Contract, newFee: string) {
    try {
        const tx = await contract.updateMaximumOperatorFee(newFee);
        console.log(`updateMaximumOperatorFee TX Hash: ${tx.hash}`);
        await tx.wait();
        console.log("✅ Successfully updated maximum operator fee");
    } catch (error: any) {
        console.error("❌ Failed to update maximum operator fee:", error);
        throw error;
    }
}

async function registerOperator(
    contract: ethers.Contract,
    publicKey: string,
    fee: string,
    setPrivate: boolean
) {
    try {
        const abiCoder = new ethers.AbiCoder()
        const encodedPublicKey = abiCoder.encode(["string"], [publicKey])

        const tx = await contract.registerOperator(encodedPublicKey, fee, setPrivate);
        console.log(`registerOperator TX Hash: ${tx.hash}`);
        await tx.wait();
        console.log(`✅ Successfully registered operator with public key ${publicKey}`);
    } catch (error: any) {
        if (error.code === 'CALL_EXCEPTION') {
            console.error(`❌ Transaction reverted while registering operator ${publicKey}:`, error);
        } else {
            console.error(`❌ Error registering operator ${publicKey}:`, error);
        }
        throw error;
    }
}

export async function registerOperators() {
    if (
        !process.env.SSV_NETWORK_ADDRESS_STAGE ||
        !process.env.OWNER_PRIVATE_KEY ||
        !process.env.RPC_URI ||
        !process.env.OPERATOR_1_PUBLIC_KEY ||
        !process.env.OPERATOR_2_PUBLIC_KEY ||
        !process.env.OPERATOR_3_PUBLIC_KEY ||
        !process.env.OPERATOR_4_PUBLIC_KEY
    ) {
        console.error("❌ One or more required environment variables are missing.");
        process.exit(1);
    }

    const operators: Operator[] = [ // TODO: get count from SSV_NODES_COUNT
        { id: 1, publicKey: process.env.OPERATOR_1_PUBLIC_KEY },
        { id: 2, publicKey: process.env.OPERATOR_2_PUBLIC_KEY },
        { id: 3, publicKey: process.env.OPERATOR_3_PUBLIC_KEY },
        { id: 4, publicKey: process.env.OPERATOR_4_PUBLIC_KEY },
    ];

    console.log('Preparing to register operators')

    const contract = await connectContract(
        process.env.RPC_URI,
        process.env.SSV_NETWORK_ADDRESS_STAGE,
        'SSVNetwork',
        process.env.OWNER_PRIVATE_KEY
    );

    const contractOwner = await contract.owner();
    console.log(`Contract Owner: ${contractOwner}`);

    const wallet = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, new ethers.JsonRpcProvider(process.env.RPC_URI));
    console.log(`Wallet Address: ${wallet.address}`)

    if (contractOwner.toLowerCase() !== wallet.address.toLowerCase()) {
        console.error("❌ The provided private key does not correspond to the contract owner.");
        process.exit(1);
    }
    console.log("✅ Verified that the wallet is the contract owner.");

    const newMaxFee = '76528650000000'; // from https://github.com/ssvlabs/ssv-network/blob/583b7b7cb1c1abc5d4c3b13bafca59bf315113b6/test/helpers/contract-helpers.ts#L32
    await updateMaximumOperatorFee(contract, newMaxFee);

    const operatorFee = '1000000000'; // taken from https://github.com/ssvlabs/ssv-network/blob/583b7b7cb1c1abc5d4c3b13bafca59bf315113b6/contracts/modules/SSVOperators.sol#L14,
    const setAsPrivate = false;

    let registeredOperators = 0;

    for (const operator of operators) {
        console.log('------------------------ Register Operator -----------------------');
        console.log(`ID: ${operator.id}`);
        console.log(`Public Key: ${operator.publicKey}`);
        console.log(`Amount: ${operatorFee}`);
        console.log(`Set As Private: ${setAsPrivate}`);
        console.log('------------------------------------------------------------------');

        try {
            await registerOperator(contract, operator.publicKey, operatorFee, setAsPrivate);
            registeredOperators++;
        } catch (error) {
            console.error(`❌ Failed to register operator with ID ${operator.id} and public key ${operator.publicKey}`);
            continue;
        }
    }

    console.log(`Registered ${registeredOperators} operators`);
}

registerOperators()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
