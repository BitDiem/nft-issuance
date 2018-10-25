pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./ERC20.sol";
import "./Voting.sol";

interface IShareTokenFactory {

  function createSharesToken(
      string tokenName, 
      string tokenSymbol,
      uint numberOfSharesToIssue,
      address initialOwner
    ) 
        external view 
        returns (ERC20);

}

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
        address voting;
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

    function issueFromFactory(
        address nft, 
        uint tokenId, 
        uint numberOfSharestoIssue,
        string tokenName,
        string tokenSymbol,
        IShareTokenFactory shareTokenFactory
    )
        public
        returns (bool)
    {
        // lookup existing (if any) metadata for the nft-tokenId tuple
        IssuanceData storage metadata = lookup[nft][tokenId];

        // only one mapping is valid at a time.  addresses must be nonzero.  number of shares to issue must be at least 1
        require(metadata.issuer == 0, "Shares are already issued against this NFT.");
        require(nft != address(0), "Not a valid NFT address");
        require(shareTokenFactory != address(0), "Not a valid address");
        require(numberOfSharestoIssue > 0, "Number of shares to issue must be greater than zero.");

        // create the ERC20 token from the factory
        address issuer = msg.sender;
        ERC20 erc20Shares = shareTokenFactory.createSharesToken(tokenName, tokenSymbol, numberOfSharestoIssue, issuer);
        
        // ensure the total supply of share tokens match the expected amount
        require(numberOfSharestoIssue == erc20Shares.totalSupply(), "ERC20 total supply does not match the expected amount");

        // map from the erc20 address to the nft-tokenId tuple
        nftKeyTupleLookup[erc20Shares].nft = nft;
        nftKeyTupleLookup[erc20Shares].tokenId = tokenId;        
        
        // transfer the NFT asset from the issuer to this contract
        ERC721 nftToken = ERC721(nft);
        nftToken.safeTransferFrom(issuer, this, tokenId);
        
        // set the metadata fields    
        metadata.issuer = issuer;
        metadata.approver = this;
        metadata.erc20Shares = erc20Shares;
        metadata.totalShares = numberOfSharestoIssue;      
    }
    
    function retire(
        address erc20Shares, 
        uint amount
    ) 
        public
        returns (bool)
    {
        NftKeyTuple storage nftKeyTuple = nftKeyTupleLookup[erc20Shares];
        address nft = nftKeyTuple.nft;
        uint tokenId = nftKeyTuple.tokenId;
        
        IssuanceData storage metaData = lookup[nft][tokenId];

        // confirm that the metadata exists
        require(metaData.erc20Shares != address(0), "No matching nft to erc20 record.");
        // confirm the amount sent is the total amount
        require(metaData.totalShares == amount, "You must send the entire token supply to retire.");     
        // confirm that the expected erc20 address matches the input
        require(metaData.erc20Shares == erc20Shares, "Shares address does not match");
          
        ERC20 shares = ERC20(erc20Shares);

        // confirm that the total token supply is being transferred
        require(shares.totalSupply() == amount, "You must send the entire token supply to retire.");

        // transfer erc20 shares from caller to this contract.  Will fail if no approval.
        shares.transferFrom(msg.sender, this, amount);
        
        // unlock the NFT and transfer it to the caller
        ERC721 nftToken = ERC721(nft);
        nftToken.safeTransferFrom(this, msg.sender, tokenId);
        
        // delete all metadata and lookup info as it is no longer needed - and saves gas costs
        expunge(nft, tokenId, erc20Shares);
        
        return true;
    }

    function setVotingAddress(
        address _nft, 
        uint _tokenId, 
        address _voting
    ) 
        public
        returns (bool)
    {
        require(_nft != address(0));
        require(_voting != address(0));

        Voting votingContract = Voting(_voting);
        require (votingContract.checkVoteStatus() == false);

        IssuanceData storage metadata = lookup[_nft][_tokenId];
        metadata.voting = _voting;
    }

    function getMetadataForNft(
        address _nft,
        uint _tokenId
    )
        public
        view
        returns (address issuer, address approver, address erc20Shares, address voting, uint totalShares)
    {
        require(_nft != address(0));
        IssuanceData storage data = lookup[_nft][_tokenId];
        return (data.issuer, data.approver, data.erc20Shares, data.voting, data.totalShares);
    }

    function mapFrom(address _erc20) public view returns (address nft, uint tokenId) {
        require(_erc20 != address(0));
        NftKeyTuple storage tuple = nftKeyTupleLookup[_erc20];
        return (tuple.nft, tuple.tokenId);
    }
    
    


    /* Private helper functions
    */
    function expunge(address nft, uint tokenId, address erc20Shares) private {
        delete lookup[nft][tokenId];
        delete nftKeyTupleLookup[erc20Shares];
    }
}