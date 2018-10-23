pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./ERC20.sol";

contract Issuance {
    
    address admin;
    address defaultApprover;
    
    // map of nft and token id to Issuance metadata
    mapping (address => mapping (uint => IssuanceData)) lookup;
    
    // map of ERC20 addresses to corresponding NFT unique id tuple
    mapping (address => NftKeyTuple) nftKeyTupleLookup;
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event WorkQueueItemAdded(address nftToken, uint tokenId, uint numberOfSharestoIssue, string tokenName);
    event ShareIssuanceComplete(address nft, uint tokenId, address erc20);
    
    struct IssuanceData {
        //address nftToken;
        address issuer;
        address approver;
        address erc20Shares;
        //uint nftTokenId;
        uint totalShares;
    }
    
    struct NftKeyTuple {
        address nft;
        uint tokenId;
    }
    
    function beginIssue(
        address _nft, 
        uint _tokenId, 
        uint _numberOfSharestoIssue,
        address _approver,
        string _tokenName
    ) 
        public
        returns (bool)
    {
        require(_nft != address(0));
        require(_approver != address(0));
        require(_numberOfSharestoIssue > 1);
        
        ERC721 nftToken = ERC721(_nft);
        nftToken.safeTransferFrom(msg.sender, this, _tokenId);
        
        IssuanceData storage metaData = lookup[_nft][_tokenId];
        
        //metaData.nftToken = _nft;
        //metaData.nftTokenId = _tokenId;
        metaData.issuer = msg.sender;
        metaData.approver = _approver;
        //metaData.erc20Shares = not set until later;
        metaData.totalShares = _numberOfSharestoIssue;
        
        emit WorkQueueItemAdded(_nft, _tokenId, _numberOfSharestoIssue, _tokenName);
        
        return true;
    }
    
    function beginIssue(address _nft, uint _tokenId, uint _numberOfSharestoIssue, string _tokenName) public returns (bool) {
        return beginIssue(_nft, _tokenId, _numberOfSharestoIssue, defaultApprover, _tokenName);
    }
    
    function completeIssue
    (
        address _nft, 
        uint _tokenId, 
        address _erc20Shares
    ) 
        public
        returns (bool)
    {
        IssuanceData storage metaData = lookup[_nft][_tokenId];

        // check that the caller is the approver
        require(metaData.approver == msg.sender);
        
        ERC20 shares = ERC20(_erc20Shares);
        
        // check that the total shares matches the actual total supply of tokens
        require(metaData.totalShares == shares.totalSupply());
        // check that the total shares are all held by the issuer
        // TODO: is this necessary?  might break certain things.  what if they auto transfer their tokens prior to this function being called
        //require(metaData.totalShares == shares.balanceOf(metaData.issuer));
        
        metaData.erc20Shares = _erc20Shares;
        
        // add relationship from erc20 address to nft lookup info
        nftKeyTupleLookup[_erc20Shares].nft = _nft;
        nftKeyTupleLookup[_erc20Shares].tokenId = _tokenId;
        
        //remove item from work queue
        
        emit ShareIssuanceComplete(_nft, _tokenId, _erc20Shares);
        return true;
    }
    
    function retire(
        address _erc20Shares, 
        uint _amount
    ) 
        public
        returns (bool)
    {
        NftKeyTuple storage nftKeyTuple = nftKeyTupleLookup[_erc20Shares];
        address _nft = nftKeyTuple.nft;
        uint _tokenId = nftKeyTuple.tokenId;
        
        IssuanceData storage metaData = lookup[_nft][_tokenId];

        require(metaData.totalShares == _amount);       // confirm the amount sent is the total amount
        require(metaData.erc20Shares == _erc20Shares);  // confirm that the expected erc20 address matches the input
        require(metaData.erc20Shares != address(0));    // confirm that the stored erc20 address has been set
        
        ERC20 shares = ERC20(_erc20Shares);
        
        require(shares.totalSupply() == _amount);       // confirm that the total token supply is being transferred

        // transfer erc20 shares from caller to this contract
        shares.transferFrom(msg.sender, this, _amount);
        
        // unlock the NFT and transfer it to the caller
        ERC721 nftToken = ERC721(_nft);
        nftToken.safeTransferFrom(this, msg.sender, _tokenId);
        
        // delete all metadata and lookup info as it is no longer needed - and saves gas costs
        expunge(_nft, _tokenId, _erc20Shares);
        
        return true;
    }
    
    function expunge(address _nft, uint _tokenId, address _erc20Shares) private {
        delete lookup[_nft][_tokenId];
        delete nftKeyTupleLookup[_erc20Shares];
    }
}