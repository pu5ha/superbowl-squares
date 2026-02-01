// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAaveV3
/// @notice Interfaces for Aave V3 protocol integration

interface IPool {
    /// @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    /// @param asset The address of the underlying asset to supply
    /// @param amount The amount to be supplied
    /// @param onBehalfOf The address that will receive the aTokens
    /// @param referralCode Code used to register the integrator originating the operation
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /// @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    /// @param asset The address of the underlying asset to withdraw
    /// @param amount The underlying amount to be withdrawn (use type(uint256).max to withdraw all)
    /// @param to The address that will receive the underlying
    /// @return The final amount withdrawn
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IWrappedTokenGatewayV3 {
    /// @notice Deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying aWETH is minted.
    /// @param pool The address of the Pool contract
    /// @param onBehalfOf The address that will receive the aWETH
    /// @param referralCode Code used to register the integrator originating the operation
    function depositETH(address pool, address onBehalfOf, uint16 referralCode) external payable;

    /// @notice Withdraws the WETH _reserves of msg.sender, sending the resulting ETH to the recipient
    /// @param pool The address of the Pool contract
    /// @param amount The amount of aWETH to withdraw and receive native ETH
    /// @param to The address that will receive the native ETH
    function withdrawETH(address pool, uint256 amount, address to) external;
}

interface IAToken {
    /// @notice Returns the scaled balance of the user
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the address of the underlying asset
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /// @notice Approve spender to transfer tokens
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfer tokens to recipient
    function transfer(address to, uint256 amount) external returns (bool);
}
