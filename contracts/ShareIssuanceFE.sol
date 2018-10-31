pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./Issuance.sol";
import "./TokenEscrow.sol";

/**
 Front-end for the entire Share issuance system.  Gives a consistent interface and address for dealing with the system
 */
contract ShareIssuanceFE is TokenEscrow {

    mapping (address => mapping (uint => Issuance)) nftToIssuanceMap;
    mapping (address => Issuance) sharesToIssuanceMap;

    function redeem(
        address erc20Shares, 
        uint amount
    ) 
        public
        returns (bool)
    {
        address redeemer = msg.sender;
        Issuance issuance = sharesToIssuanceMap[erc20Shares];
        return issuance.redeem(redeemer, erc20Shares, amount);
    }

    function findByNftAddressAndTokenId(
        address nft,
        uint tokenId
    )
        public
        view
        returns (address issuer, address erc20Shares, uint totalShares)
    {
        Issuance issuance = nftToIssuanceMap[nft][tokenId];
        return issuance.findByNftAddressAndTokenId(nft, tokenId);
    }

    function findBySharesAddress(address erc20) 
        public 
        view 
        returns (address nft, uint tokenId) 
    {
        Issuance issuance = sharesToIssuanceMap[erc20];
        return issuance.findBySharesAddress(erc20);
    }
}