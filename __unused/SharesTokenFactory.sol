pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../issuers/ITokenFactory.sol";
import "./SharesToken.sol";

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
        return token;
    }

}