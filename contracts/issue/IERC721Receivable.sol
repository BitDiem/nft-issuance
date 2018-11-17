pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title IERC721Receivable
 * @dev Reusable implementation of of the IERC721Receiver interface
 */
contract IERC721Receivable is IERC721Receiver {

    bytes4 constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  
    // Implement the IERC721Receiver interface to handle safeTransferFrom correctly
    function onERC721Received(address, address, uint, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }

}