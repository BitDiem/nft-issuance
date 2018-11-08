pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";

contract MockNft is ERC721Full {
    constructor() ERC721Full("MockNft", "MNFT") public 
    {
    }

    function mint(uint tokenId) public {
        _mint(msg.sender, tokenId);
    }
}