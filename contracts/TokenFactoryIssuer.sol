pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./ERC20.sol";
import "./ITokenFactory.sol";
import "./Issuance.sol";

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
        require(nft != address(0), "Not a valid NFT address");
        // TODO: ensure address is erc721
        require(shareTokenFactory != address(0), "Not a valid address");
        require(numberOfSharestoIssue > 0, "Number of shares to issue must be greater than zero.");

        // create the ERC20 token from the factory
        address issuer = msg.sender;
        ERC20 erc20Shares = shareTokenFactory.createSharesToken(tokenName, tokenSymbol, numberOfSharestoIssue, issuer);
        
        // ensure the total supply of share tokens match the expected amount
        require(numberOfSharestoIssue == erc20Shares.totalSupply(), "ERC20 total supply does not match the expected amount");
    
        // bind the nft to the shares
        _issuance.issueAgainstExisting(issuer, nft, tokenId, erc20Shares, numberOfSharestoIssue);
    }
}