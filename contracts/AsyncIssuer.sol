pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./ERC20.sol";
import "./Issuance.sol";

contract AsyncIssuer {
    
    address admin;
    address defaultApprover;
    Issuance _issuance;
    
    // map of nft and token id to Issuance metadata
    mapping (address => mapping (uint => IssuanceData)) lookup;
    
    event WorkQueueItemAdded(address nftToken, uint tokenId, uint numberOfSharestoIssue, string tokenName);
    event ShareIssuanceComplete(address nft, uint tokenId, address erc20);
    
    struct IssuanceData {
        address nft;
        address issuer;
        address approver;
        address erc20Shares;
        address voting;
        uint tokenId;
        uint totalShares;
        string tokenName;
        string tokenSymbol;
    }

    constructor (address issuance) public {
        _issuance = Issuance(issuance);
    }
    
    function beginIssue(
        address nft, 
        uint tokenId, 
        uint numberOfSharestoIssue,
        address approver,
        string tokenName,
        string tokenSymbol
    ) 
        public
        returns (bool)
    {
        require(nft != address(0));
        // TODO: check that nft is ERC721
        require(approver != address(0));
        require(numberOfSharestoIssue > 0);
        
        address issuer = msg.sender;
        IssuanceData storage item = lookup[nft][tokenId];
        
        item.nft = nft;
        item.issuer = issuer;
        item.approver = approver;
        //item.erc20Shares = not set until later;
        item.tokenId = tokenId;
        item.totalShares = numberOfSharestoIssue;
        item.tokenName = tokenName;
        item.tokenSymbol = tokenSymbol;
        
        emit WorkQueueItemAdded(nft, tokenId, numberOfSharestoIssue, tokenName);
        
        return true;
    }
    
    function completeIssue
    (
        address nft, 
        uint tokenId, 
        address erc20Shares
    ) 
        public
        returns (bool)
    {
        IssuanceData storage item = lookup[nft][tokenId];

        // check that the caller is the approver
        require(item.approver == msg.sender);
        
        ERC20 shares = ERC20(erc20Shares);
        
        // check that the total shares matches the actual total supply of tokens
        require(item.totalShares == shares.totalSupply());
        //require (item.tokenName == shares.) // no way to check the token name?
        //require(item.tokenSymbol == shares.) // no way to check the token symbol?

        // check that the total shares are all held by the issuer
        // TODO: is this necessary?  might break certain things.  what if they auto transfer their tokens prior to this function being called
        //require(item.totalShares == shares.balanceOf(item.issuer));
        
        item.erc20Shares = erc20Shares;
        
        //remove item from work queue

        // bind the nft to the shares
        _issuance.issueAgainstExisting(item.issuer, item.nft, item.tokenId, item.erc20Shares, item.totalShares);
        
        emit ShareIssuanceComplete(nft, tokenId, erc20Shares);
        return true;
    }
}