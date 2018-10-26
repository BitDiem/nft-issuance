pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./ERC20.sol";
import "./Voting.sol";

contract Issuance {
    
    address admin;
    address defaultApprover;
    
    // map of nft and token id to Issuance metadata
    mapping (address => mapping (uint => IssuanceData)) lookup;
    
    // map of ERC20 addresses to corresponding NFT unique id tuple
    mapping (address => NftKeyTuple) nftKeyTupleLookup;
    
    event SharesBoundToNft(address issuer, address nft, uint tokenId, address erc20, uint numberOfSharesToIssue);
    
    struct IssuanceData {
        address issuer;
        address erc20Shares;
        address voting;
        uint totalShares;
    }
    
    struct NftKeyTuple {
        address nft;
        uint tokenId;
    }

    function issueAgainstExisting(
        address issuer,
        address nft, 
        uint tokenId,
        address erc20,
        uint numberOfSharesToIssue    
    )
        public
        returns (bool)
    {
        // lookup existing (if any) metadata for the nft-tokenId tuple
        IssuanceData storage metadata = lookup[nft][tokenId];

        // only one mapping between an NFT and erc20 shares is valid at a time.
        require(metadata.issuer == 0, "Shares are already issued against this NFT.");

        // all input addresses must be nonzero
        require(issuer != address(0), "Not a valid issuer address");
        require(nft != address(0), "Not a valid NFT address.");
        require(erc20 != address(0), "Not a valid erc20 address.");

        // number of shares to issue must be at least 1
        require(numberOfSharesToIssue > 0, "Number of shares to issue must be greater than zero.");

        ERC20 erc20Shares = ERC20(erc20);

        // ensure the total supply of share tokens match the expected amount
        require(numberOfSharesToIssue == erc20Shares.totalSupply(), "ERC20 total supply does not match the expected amount");

        // map from the erc20 address to the nft-tokenId tuple
        nftKeyTupleLookup[erc20Shares].nft = nft;
        nftKeyTupleLookup[erc20Shares].tokenId = tokenId;        
        
        // transfer the NFT asset from the issuer to this contract
        ERC721 nftToken = ERC721(nft);
        nftToken.safeTransferFrom(issuer, this, tokenId);
        
        // set the metadata fields    
        metadata.issuer = issuer;
        metadata.erc20Shares = erc20Shares;
        metadata.totalShares = numberOfSharesToIssue;

        // emit the appropriate event
        emit SharesBoundToNft(issuer, nft, tokenId, erc20, numberOfSharesToIssue);
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
        
        IssuanceData storage metadata = lookup[nft][tokenId];

        // confirm that the metadata exists
        require(metadata.erc20Shares != address(0), "No matching nft to erc20 record.");
        // confirm the amount sent is the total amount
        require(metadata.totalShares == amount, "You must send the entire token supply to retire.");     
        // confirm that the expected erc20 address matches the input
        require(metadata.erc20Shares == erc20Shares, "Shares address does not match");
          
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
        address nft, 
        uint tokenId, 
        address voting
    ) 
        public
        returns (bool)
    {
        require(nft != address(0));
        require(voting != address(0));

        Voting votingContract = Voting(voting);
        require (votingContract.checkVoteStatus() == false);

        // Approve the voting contract for transferring the NFT out?  This might be a bad idea.  Might need to invert this control
        ERC721 nftContract = ERC721(nft);
        nftContract.approve(nft, tokenId);

        IssuanceData storage metadata = lookup[nft][tokenId];
        metadata.voting = voting;
    }

    function distributeProposal(address nft, uint tokenId, address paymentType, uint paymentAmount) public
    {
        
        IssuanceData storage metadata = lookup[nft][tokenId];

        require(msg.sender == metadata.voting);

        // loop through shares owners, distribute paymentType accordingly and in proportion
    }

    function getMetadataForNft(
        address _nft,
        uint _tokenId
    )
        public
        view
        returns (address issuer, address erc20Shares, address voting, uint totalShares)
    {
        require(_nft != address(0));
        IssuanceData storage data = lookup[_nft][_tokenId];
        return (data.issuer, data.erc20Shares, data.voting, data.totalShares);
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