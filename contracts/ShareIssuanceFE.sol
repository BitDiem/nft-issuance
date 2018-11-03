pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./Issuance.sol";
import "./TokenEscrow.sol";
import "./issuers/TokenFactoryIssuer.sol";
import "./issuers/ITokenFactory.sol";
import "./issuers/SharestokenFactory.sol";


/**
 Front-end for the entire Share issuance system.  Gives a consistent interface and address for dealing with the system
 */
contract ShareIssuanceFE is TokenEscrow {

    //mapping (address => mapping (uint => Issuance)) nftToIssuanceMap;
    //mapping (address => Issuance) sharesToIssuanceMap;

    Issuance private _issuance;

    constructor (Issuance issuance) {
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
        return issuance.redeem(redeemer, erc20Shares, amount);
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
}