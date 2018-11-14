pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "./ERC20Enumerable.sol";

/**
 * @title SharesToken
 * @dev A standard ERC20 token derived from Open Zeppelin's implementation - 
 * with the addition of an internal array to track all current shareholders.
 */
contract SharesToken is IERC20, ERC20Detailed, ERC20Enumerable {

    uint8 private constant DECIMALS = 18;

    constructor(
        string name, 
        string symbol, 
        address holder,
        uint totalSupply
    ) 
        ERC20Detailed(name, symbol, DECIMALS) 
        public 
    {
        _mint(holder, totalSupply);
    }
}