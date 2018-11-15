pragma solidity ^0.4.24;

import "../token/SharesToken.sol";

library StandardTokenFactory {

    enum TokenType {
        ERC20,
        ERC1450
    }

    function createTokenForCaller(
        string tokenName, 
        string tokenSymbol, 
        uint supply,
        TokenType tokenType
    ) 
        internal
        returns (address)
    {
        address holder = msg.sender;

        address shares;

        if (TokenType.ERC20 == tokenType) {
            shares = new SharesToken(tokenName, tokenSymbol, holder, supply);
        }
        else if (TokenType.ERC1450 == tokenType) {
            revert("ERC1450 not supported yet");
        }
        else {
            revert("Not a valid token type");
        }

        return shares;
    }
}