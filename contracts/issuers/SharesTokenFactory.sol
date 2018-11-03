pragma solidity ^0.4.24;

import "./ITokenFactory.sol";
import "../SharesToken.sol";

contract SharesTokenFactory is ITokenFactory {

    function createSharesToken(
      string tokenName, 
      string tokenSymbol,
      uint numberOfSharesToIssue,
      address initialOwner
    ) 
        external 
        returns (IERC20)
    {
        SharesToken token = new SharesToken(tokenName, tokenSymbol, initialOwner, numberOfSharesToIssue);
        //token.mint
        return token;
    }

}