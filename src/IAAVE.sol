// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IAAVE {
    function deposit(
        address token,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(address token, uint256 amount, address to) external;

    function balanceOf(
        address user,
        address token
    ) external view returns (uint256);
}
