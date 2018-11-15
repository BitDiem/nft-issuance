pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./Issuance.sol";
import "./issuers/TokenFactoryIssuer.sol";
import "./issuers/ITokenFactory.sol";
import "./token/SharestokenFactory.sol";
import "./voting/VotingRightsManager.sol";
import "./voting/systems/IVoting.sol";


/**
 Front-end for the entire Share issuance system.  Gives a consistent interface and address for dealing with the system
 */
contract IssuanceFrontEnd {

    //mapping (address => mapping (uint => Issuance)) nftToIssuanceMap;
    //mapping (address => Issuance) sharesToIssuanceMap;

    Issuance private _issuance;
    VotingRightsManager _votingRightsManager;

    constructor (Issuance issuance) public {
        _issuance = issuance;
    }

    function standardIssue(
        address nft, 
        uint tokenId, 
        string tokenName, 
        string tokenSymbol, 
        uint supply
    ) 
        public
        returns (bool)
    {
        address issuer = msg.sender;

        //Issuance issuance = nftToIssuanceMap[nft][tokenId];

        ITokenFactory factory = new SharesTokenFactory();
        TokenFactoryIssuer module = new TokenFactoryIssuer(_issuance);
        return module.issueFromFactory(nft, tokenId, supply, issuer, tokenName, tokenSymbol, factory);
    }

    function redeem(
        address erc20Shares, 
        uint amount
    ) 
        public
        returns (bool)
    {
        address redeemer = msg.sender;
        Issuance issuance = _issuance;// sharesToIssuanceMap[erc20Shares];
        issuance.redeem(redeemer, erc20Shares, amount);
    }

    function find(
        address nft,
        uint tokenId
    )
        public
        view
        returns (address issuer, address erc20Shares, uint totalShares)
    {
        Issuance issuance = _issuance;// nftToIssuanceMap[nft][tokenId];
        return issuance.find(nft, tokenId);
    }

    function find(address erc20) 
        public 
        view 
        returns (address nft, uint tokenId) 
    {
        Issuance issuance = _issuance;// sharesToIssuanceMap[erc20];
        return issuance.find(erc20);
    }

    // who can set the voting manager?  anyone! but the proposed module must be on an approved list
    function setVotingManager(
        address nft, 
        uint tokenId, 
        IVoting votingModule
    ) 
        public
        returns (bool)
    {
        return _votingRightsManager.setVotingManager(nft, tokenId, votingModule);
    }

    function getVotingManager(
        address nft, 
        uint tokenId
    )
        public
        view
        returns (address)
    {
        return _votingRightsManager.getVotingManager(nft, tokenId);
    }
}