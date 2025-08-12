const { ethers } = require("hardhat");

async function main() {
    console.log("Deploying Minesweeper contract to Somnia Testnet...");
    
    // Get the ContractFactory and Signers here
    const [deployer] = await ethers.getSigners();
    
    if (!deployer) {
        throw new Error("No deployer account found. Please check your PRIVATE_KEY in .env file");
    }
    
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");
    
    // Deploy the contract
    const Minesweeper = await ethers.getContractFactory("Minesweeper");
    console.log("Deploying contract...");
    const minesweeper = await Minesweeper.deploy();
    
    console.log("Waiting for deployment confirmation...");
    await minesweeper.waitForDeployment();
    
    const contractAddress = await minesweeper.getAddress();
    console.log("Minesweeper contract deployed to:", contractAddress);
    console.log("Contract owner:", await minesweeper.owner());
    
    // Save deployment info
    const deploymentInfo = {
        contractAddress: contractAddress,
        deployer: deployer.address,
        network: "Somnia Testnet",
        deployedAt: new Date().toISOString(),
        transactionHash: minesweeper.deploymentTransaction().hash
    };
    
    console.log("Deployment Info:", JSON.stringify(deploymentInfo, null, 2));
    
    // Instructions for updating frontend
    console.log("\n=== NEXT STEPS ===");
    console.log("1. Update CONTRACT_ADDRESS in index.html with:", contractAddress);
    console.log("2. Fund the contract with some ETH if needed");
    console.log("3. Test the game by connecting your wallet and starting a game");
    console.log("4. Verify contract on block explorer (optional):");
    console.log("   npx hardhat verify --network somnia", contractAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Deployment failed:", error);
        process.exit(1);
    });