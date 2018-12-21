pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/ownership/Secondary.sol";
import "./utils/ERC721Utils.sol";
import "./issue/IERC721Receivable.sol";

/**
 * @dev Encapsulates ownership transfer and withdrawal of an NFT.  Whichever contract is the "primary" to this will be able to 
 * withdraw any stored NFT.
 */
contract NftBank is Secondary, IERC721Receivable {

    /*address _nft;
    uint _tokenId;
    NftApprovedTransferer _approvedTransferer;

    constructor(address nft, uint tokenId, NftApprovedTransferer approvedTransferer) public {
        _nft = nft;
        _tokenId = tokenId;
        _approvedTransferer = approvedTransferer;
    }*/

    function takeFrom(
        address from, 
        address nft, 
        uint tokenId, 
        NftApprovedTransferer approvedTransferer
    ) 
        onlyPrimary 
        public  
    {
        approvedTransferer.transferNft(nft, tokenId, from, address(this));
    }

    /*function depositFrom(address from) onlyPrimary public  {
        _approvedTransferer.transferNft(_nft, _tokenId, from, address(this));
    }*/

    function giveTo(
        address to, 
        address nft, 
        uint tokenId
    ) 
        onlyPrimary 
        public 
    {
        IERC721 nftToken = IERC721(nft);
        nftToken.transferFrom(address(this), to, tokenId);
    }

    /*function withdrawTo(address to) onlyPrimary public {
        IERC721 nftToken = IERC721(_nft);
        nftToken.safeTransferFrom(address(this), to, _tokenId);
    }*/
}

contract NftApprovedTransferer {

    using ERC721Utils for IERC721;

    function transferNft(address nft, uint tokenId, address from, address to) public {
        IERC721 nftToken = IERC721(nft);
        require(nftToken.isApprovedOrOwner(address(this), tokenId), "Transfer approval required.");
        nftToken.safeTransferFrom(from, to, tokenId);
    }

}