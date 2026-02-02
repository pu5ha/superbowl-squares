// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPool, IWrappedTokenGatewayV3, IAToken} from "../../src/interfaces/IAaveV3.sol";

/// @title MockAToken
/// @notice Mock aToken for testing Aave integration
contract MockAToken is IAToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    address public underlyingAsset;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Simulate yield accrual
    uint256 public yieldMultiplier = 100; // 100 = no yield, 101 = 1% yield, etc.

    constructor(string memory _name, string memory _symbol, address _underlying) {
        name = _name;
        symbol = _symbol;
        underlyingAsset = _underlying;
    }

    function UNDERLYING_ASSET_ADDRESS() external view returns (address) {
        return underlyingAsset;
    }

    function balanceOf(address account) external view returns (uint256) {
        // Apply yield multiplier to simulate interest accrual
        return (_balances[account] * yieldMultiplier) / 100;
    }

    function rawBalanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 effectiveBalance = (_balances[msg.sender] * yieldMultiplier) / 100;
        require(effectiveBalance >= amount, "Insufficient balance");

        // Calculate proportional raw balance to transfer
        uint256 rawAmount = (amount * 100) / yieldMultiplier;
        _balances[msg.sender] -= rawAmount;
        _balances[to] += rawAmount;
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    // Mock functions for testing
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
    }

    function burn(address from, uint256 amount) external {
        _balances[from] -= amount;
    }

    function setYieldMultiplier(uint256 _multiplier) external {
        yieldMultiplier = _multiplier;
    }

    /// @notice Simulate Aave rounding loss by reducing balance
    /// @dev Used to test the fix for withdrawal when balance < expected amount
    function simulateRoundingLoss(address account, uint256 lossAmount) external {
        require(_balances[account] >= lossAmount, "Loss exceeds balance");
        _balances[account] -= lossAmount;
    }
}

/// @title MockAavePool
/// @notice Mock Aave Pool for testing
contract MockAavePool is IPool {
    mapping(address => MockAToken) public aTokens;

    function setAToken(address underlying, address aToken) external {
        aTokens[underlying] = MockAToken(aToken);
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 /* referralCode */) external {
        // Real Aave reverts on zero amount
        require(amount > 0, "INVALID_AMOUNT");

        // Transfer underlying from sender
        (bool success,) = asset.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount)
        );
        require(success, "Transfer failed");

        // Mint aTokens to onBehalfOf
        aTokens[asset].mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        // Burn aTokens from sender
        aTokens[asset].burn(msg.sender, amount);

        // Transfer underlying to recipient
        (bool success,) = asset.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "Transfer failed");

        return amount;
    }
}

/// @title MockWETHGateway
/// @notice Mock WETH Gateway for testing ETH deposits/withdrawals
contract MockWETHGateway is IWrappedTokenGatewayV3 {
    MockAToken public aWETH;

    constructor(address _aWETH) {
        aWETH = MockAToken(_aWETH);
    }

    function depositETH(address /* pool */, address onBehalfOf, uint16 /* referralCode */) external payable {
        // Real Aave WETH Gateway reverts on zero amount
        require(msg.value > 0, "INVALID_AMOUNT");

        // Mint aWETH to onBehalfOf
        aWETH.mint(onBehalfOf, msg.value);
    }

    function withdrawETH(address /* pool */, uint256 amount, address to) external {
        // Check allowance
        uint256 allowed = aWETH.allowance(msg.sender, address(this));
        require(allowed >= amount, "Insufficient allowance");

        // Burn aWETH from sender
        aWETH.burn(msg.sender, amount);

        // Send ETH to recipient
        (bool success,) = to.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    // Receive ETH for withdrawals
    receive() external payable {}
}
