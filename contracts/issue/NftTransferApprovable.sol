pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract NftTransferApprovable {

    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (address => mapping (address => mapping (address => mapping (uint256 => bool)))) private _nftApprovals;

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
    */
    /*function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        //emit Approval(msg.sender, spender, value);
        return true;
    }*/
    function setApprovalForNft(
        address spender, 
        address nft, 
        uint tokenId, 
        bool value
    ) 
        public 
    {
        require(spender != address(0));

        _nftApprovals[msg.sender][spender][nft][tokenId] = value;
        //emit Approval(msg.sender, spender, value);
    }

    function setApprovalForAll(
        address spender, 
        bool value
    ) 
        public 
    {
        require(spender != address(0));

        _operatorApprovals[msg.sender][spender] = value;
    }

    function isApprovedForNft(
        address owner, 
        address spender, 
        address nft, 
        uint tokenId
    ) 
        public 
        view 
        returns (bool) 
    {
        return _nftApprovals[owner][spender][nft][tokenId];
    }

    function isApprovedForAll(
        address owner, 
        address spender
    ) 
        public 
        view 
        returns (bool) 
    {
        return _operatorApprovals[owner][spender];
    }

}