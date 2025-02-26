// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./IAAVE.sol";

contract LotterySystem {
    // address public oracleAddress;
    address public aaveInstance;

    uint public accruedInterest;
    uint public totalDeposits;

    bool public hasClaimedPrize = false;

    address public usdcTokenAddress;

    mapping(address user => uint256 amount) public deposits;
    address[] public tickets; // array of addresses that have tickets

    uint public drawingTime;
    bool public drawingCompleted = false;
    address public winner;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        // address _oracleAddress,
        address _aaveInstance
    ) {
        //oracleAddress = _oracleAddress;
        aaveInstance = _aaveInstance;
        usdcTokenAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8; // Updated USDC address
        drawingTime = block.timestamp + 7 days;
        owner = msg.sender; // Set the owner
    }

    function deposit() public {
        require(block.timestamp < drawingTime, "Drawing has already happened");
        uint amount = 10 * 10 ** 6;

        // transfer usdc from the user to the contract
        ERC20 usdcToken = ERC20(usdcTokenAddress);
        usdcToken.transferFrom(msg.sender, address(this), amount);

        // add the user to the tickets array
        tickets.push(msg.sender);

        // update the total deposits
        totalDeposits += amount;

        // update the user's deposit
        deposits[msg.sender] += amount;

        // send to aave for that yummy yield
        depositInAave(amount);
    }

    function withdraw(uint256 amount) public {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        require(
            block.timestamp < drawingTime,
            "Cannot withdraw after drawing time"
        );

        // Withdraw from Aave
        withdrawFromAave(amount);

        // Update deposits
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        // Transfer USDC back to user
        ERC20 usdcToken = ERC20(usdcTokenAddress);
        usdcToken.transfer(msg.sender, amount);

        // Remove one ticket for every 10 USDC withdrawn
        uint256 ticketsToRemove = amount / (10 * 10 ** 6);
        for (uint i = 0; i < ticketsToRemove; i++) {
            for (uint j = tickets.length - 1; j >= 0; j--) {
                if (tickets[j] == msg.sender) {
                    tickets[j] = tickets[tickets.length - 1];
                    tickets.pop();
                    break;
                }
            }
        }
    }

    function claimPrice() public {
        require(drawingCompleted, "Drawing is already completed");
        winner = tickets[getRandomNumber()];
        drawingCompleted = true;
    }

    function harvestInterest() public returns (uint256) {
        IAAVE aave = IAAVE(aaveInstance);
        uint256 currentBalance = aave.balanceOf(
            address(this),
            usdcTokenAddress
        );
        uint256 interest = currentBalance - totalDeposits;
        accruedInterest = interest;
        return interest;
    }

    function sendPrize() external {
        require(drawingCompleted, "Drawing is not completed");
        require(msg.sender == winner, "You are not the winner");
        require(hasClaimedPrize == false, "You have already claimed the prize");

        uint interestGenerated = harvestInterest();
        ERC20 usdcToken = ERC20(usdcTokenAddress);
        usdcToken.transfer(winner, interestGenerated);
        hasClaimedPrize = true;
    }

    function depositInAave(uint256 amount) internal {
        IAAVE aave = IAAVE(aaveInstance);
        aave.deposit(usdcTokenAddress, amount, address(this), 0);
    }

    function withdrawFromAave(uint256 amount) internal {
        IAAVE aave = IAAVE(aaveInstance);
        aave.withdraw(usdcTokenAddress, amount, address(this));
    }

    function getRandomNumber() internal pure returns (uint256) {
        return 6;
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(
            amount <= totalDeposits + accruedInterest,
            "Amount exceeds total balance"
        );

        // Withdraw from Aave
        withdrawFromAave(amount);

        // Transfer USDC to owner
        ERC20 usdcToken = ERC20(usdcTokenAddress);
        usdcToken.transfer(owner, amount);
    }
}
