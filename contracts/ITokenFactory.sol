pragma solidity ^0.4.24;

import "./ERC20.sol";

interface ITokenFactory {

  function createSharesToken(
      string tokenName, 
      string tokenSymbol,
      uint numberOfSharesToIssue,
      address initialOwner
    ) 
        external view 
        returns (ERC20);

}