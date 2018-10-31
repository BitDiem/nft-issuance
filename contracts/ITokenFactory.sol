pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface ITokenFactory {

  function createSharesToken(
      string tokenName, 
      string tokenSymbol,
      uint numberOfSharesToIssue,
      address initialOwner
    ) 
        external view 
        returns (IERC20);

}