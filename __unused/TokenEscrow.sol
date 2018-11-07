pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

contract TokenEscrow {

    event TokenEscrowed(address party, address nft, uint tokenId);
    event TokenDisbursed(address party, address nft, uint tokenId);

    function hold(
        address party, 
        address nft, 
        uint tokenId
    ) 
        public
        returns (bool)
    {
        IERC721 nftToken = IERC721(nft);
        nftToken.safeTransferFrom(party, this, tokenId);
        emit TokenEscrowed(party, nft, tokenId);
        return true;
    }

    function release(
        address party,
        address nft,
        uint tokenId
    )
        public
        returns (bool)
    {
        IERC721 nftToken = IERC721(nft);
        nftToken.safeTransferFrom(this, party, tokenId);
        emit TokenDisbursed(party, nft, tokenId);
        return true;
    }
}