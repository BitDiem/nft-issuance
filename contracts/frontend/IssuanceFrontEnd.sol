pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StandardTokenFactory.sol";
import "../Issuance.sol";
import "../token/ITokenFactory.sol";
import "../voting/VotingRightsManager.sol";
import "../voting/systems/IVoting.sol";
import "../utils/ERC721Utils.sol";



/**
 Front-end for the entire Share issuance system.  Gives a consistent interface and address for dealing with the system
 */
contract IssuanceFrontEnd {

    using ERC721Utils for IERC721;

    //mapping (address => mapping (uint => Issuance)) nftToIssuanceMap;
    //mapping (address => Issuance) sharesToIssuanceMap;

    Issuance private _issuance;
    VotingRightsManager _votingRightsManager;

    constructor (Issuance issuance) public {
        _issuance = issuance;
    }

    function issue(
        address nft, 
        uint tokenId, 
        string tokenName, 
        string tokenSymbol, 
        uint supply,
        StandardTokenFactory.TokenType tokenType
    ) 
        public
    {
        validateNft(nft, tokenId);

        address issuer = msg.sender;
        address shares = StandardTokenFactory.createTokenForCaller(tokenName, tokenSymbol, supply, tokenType);
        _issuance.issue(issuer, nft, tokenId, shares, supply);
    }

    function issue(
        address nft, 
        uint tokenId, 
        string tokenName, 
        string tokenSymbol, 
        uint supply,
        ITokenFactory tokenFactory
    ) 
        public
    {
        validateNft(nft, tokenId);

        address issuer = msg.sender;
        address shares = tokenFactory.createToken(tokenName, tokenSymbol, supply, issuer);
        _issuance.issue(issuer, nft, tokenId, shares, supply);
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

    function validateNft(address nft, uint tokenId) private view {
        require(nft != address(0), "Invalid NFT address");
        IERC721 nftToken = IERC721(nft);
        require(nftToken.isApprovedOrOwner(address(_issuance), tokenId), "Transfer approval required.");
    }
}