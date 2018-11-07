pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

library ERC721Utils {

    /**
     * Code is copied whole cloth from the Open Zeppelin ERC721 implementation.  
       Where it is an internal function there, it is exposed as a static function here
     */
    function isApprovedOrOwner(
        IERC721 erc721,
        address spender,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = erc721.ownerOf(tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
            spender == owner ||
            erc721.getApproved(tokenId) == spender ||
            erc721.isApprovedForAll(owner, spender)
        );
    }

}