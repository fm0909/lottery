// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/LotterySystem.sol";

contract DeployLottery is Script {
    function run() external {
        // Read the private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Sepolia AAVE v3 Pool address
        address aaveV3Pool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;

        // Deploy LotterySystem with only aaveV3Pool parameter
        LotterySystem lottery = new LotterySystem(aaveV3Pool);

        console.log("LotterySystem deployed at:", address(lottery));

        vm.stopBroadcast();
    }
}
