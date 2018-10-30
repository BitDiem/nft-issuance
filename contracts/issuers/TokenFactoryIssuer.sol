pragma solidity ^0.4.24;

import "../ERC20.sol";
import "../ITokenFactory.sol";
import "../Issuance.sol";

contract TokenFactoryIssuer {
    
    address admin;
    address defaultApprover;
    Issuance _issuance;
    
    event ShareIssuanceComplete(address nft, uint tokenId, address erc20);

    constructor (address issuance) public {
        _issuance = Issuance(issuance);
    }

    function issueFromFactory(
        address nft, 
        uint tokenId, 
        uint numberOfSharestoIssue,
        string tokenName,
        string tokenSymbol,
        ITokenFactory shareTokenFactory
    )
        public
        returns (bool)
    {
        // create the ERC20 token from the factory
        address issuer = msg.sender;
        ERC20 erc20Shares = shareTokenFactory.createSharesToken(tokenName, tokenSymbol, numberOfSharestoIssue, issuer);
    
        // bind the nft to the shares
        _issuance.issue(issuer, nft, tokenId, erc20Shares, numberOfSharestoIssue);
    }
}

contract TokenFactoryIssuerWithInheritance is Issuance {
    
    function issueFromFactory(
        address nft, 
        uint tokenId, 
        uint numberOfSharestoIssue,
        string tokenName,
        string tokenSymbol,
        ITokenFactory shareTokenFactory
    )
        public
        returns (bool)
    {
        address issuer = msg.sender;

        // create the ERC20 token from the factory
        ERC20 erc20Shares = shareTokenFactory.createSharesToken(tokenName, tokenSymbol, numberOfSharestoIssue, issuer);
    
        // bind the nft to the shares
        issue(issuer, nft, tokenId, erc20Shares, numberOfSharestoIssue);
    }
}