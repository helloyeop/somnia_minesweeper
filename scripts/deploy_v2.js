const { ethers } = require("hardhat");

async function main() {
    console.log("Deploying MinesweeperV2 contract to Somnia Testnet...");
    
    // Get the ContractFactory and Signers here
    const [deployer] = await ethers.getSigners();
    
    if (!deployer) {
        throw new Error("No deployer account found. Please check your PRIVATE_KEY in .env file");
    }
    
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");
    
    // Deploy the contract
    const MinesweeperV2 = await ethers.getContractFactory("MinesweeperV2");
    console.log("Deploying MinesweeperV2 contract...");
    const minesweeperV2 = await MinesweeperV2.deploy();
    
    console.log("Waiting for deployment confirmation...");
    await minesweeperV2.waitForDeployment();
    
    const contractAddress = await minesweeperV2.getAddress();
    console.log("MinesweeperV2 contract deployed to:", contractAddress);
    console.log("Contract owner:", await minesweeperV2.owner());
    
    // Test difficulty configurations
    console.log("\n=== Difficulty Configurations ===");
    for (let i = 0; i < 3; i++) {
        const config = await minesweeperV2.getDifficultyConfig(i);
        const difficultyNames = ['EASY', 'MEDIUM', 'HARD'];
        console.log(`${difficultyNames[i]}:`, {
            rows: config.rows,
            cols: config.cols,
            mines: config.mines,
            entryFee: ethers.formatEther(config.entryFee),
            winningReward: ethers.formatEther(config.winningReward)
        });
    }
    
    // Save deployment info
    const deploymentInfo = {
        contractAddress: contractAddress,
        deployer: deployer.address,
        network: "Somnia Testnet",
        deployedAt: new Date().toISOString(),
        transactionHash: minesweeperV2.deploymentTransaction().hash,
        version: "V2",
        features: [
            "Multiple difficulty levels",
            "Dynamic board sizes",
            "Difficulty-based rewards",
            "Enhanced statistics tracking"
        ]
    };
    
    console.log("\n=== Deployment Info ===");
    console.log(JSON.stringify(deploymentInfo, null, 2));
    
    // Instructions for updating frontend
    console.log("\n=== NEXT STEPS ===");
    console.log("1. Update CONTRACT_ADDRESS in index_v2.html with:", contractAddress);
    console.log("2. Replace the current index.html with index_v2.html (or rename):");
    console.log("   mv index_v2.html index.html");
    console.log("3. Test the game with different difficulty levels");
    console.log("4. Fund the contract with some ETH if needed");
    console.log("5. Verify contract on block explorer (optional):");
    console.log("   npx hardhat verify --network somnia", contractAddress);
    
    console.log("\n=== Contract Features ===");
    console.log("✅ 3 Difficulty Levels (Easy, Medium, Hard)");
    console.log("✅ Dynamic Board Sizes (9x9, 16x16, 16x30)");
    console.log("✅ Scaled Entry Fees (0.0005, 0.001, 0.002 ETH)");
    console.log("✅ Scaled Rewards (0.001, 0.003, 0.008 ETH)");
    console.log("✅ Per-Difficulty Statistics Tracking");
    console.log("✅ Enhanced Scoring System");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Deployment failed:", error);
        process.exit(1);
    });