pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract SharesToken is IERC20, ERC20, ERC20Detailed {

    uint8 private constant DECIMALS = 18;

    mapping (address => uint256) private percentages;

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

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);

        percentages[from] = balanceOf(from) / totalSupply();
        percentages[to] = balanceOf(to) / totalSupply();
    }

}