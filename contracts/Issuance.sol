pragma solidity ^0.4.24;

//import "./ERC721.sol";
import "./ERC20.sol";
import "./TokenEscrow.sol";

contract Issuance {
    
    TokenEscrow _escrow;
    
    // map of nft and token id to Issuance metadata
    mapping (address => mapping (uint => IssuanceData)) lookup;
    
    // map of ERC20 addresses to corresponding NFT unique id tuple
    mapping (address => NftKeyTuple) nftKeyTupleLookup;
    
    event SharesBoundToNft(address issuer, address nft, uint tokenId, address erc20, uint numberOfSharesToIssue);
    
    struct IssuanceData {
        address issuer;
        address erc20Shares;
        uint totalShares;
    }
    
    struct NftKeyTuple {
        address nft;
        uint tokenId;
    }

    function issue(
        address issuer,
        address nft, 
        uint tokenId,
        address erc20,
        uint numberOfSharesToIssue    
    )
        public
        returns (bool)
    {
        // all input addresses must be nonzero
        require(issuer != address(0), "Invalid issuer address");
        require(nft != address(0), "Invalid NFT address.");
        require(erc20 != address(0), "Invalid erc20 address.");

        // number of shares to issue must be at least 1
        require(numberOfSharesToIssue > 0, "Number of shares to issue must be greater than zero.");

        // lookup existing metadata for the nft-tokenId tuple
        IssuanceData storage metadata = lookup[nft][tokenId];

        // only one mapping between an NFT and erc20 shares is valid at a time.
        require(metadata.issuer == address(0), "Shares are already issued against this NFT.");
    
        ERC20 erc20Shares = ERC20(erc20);

        // ensure the total supply of share tokens match the expected amount
        require(numberOfSharesToIssue == erc20Shares.totalSupply(), "ERC20 total supply does not match the expected amount");

        // map from the erc20 address to the nft-tokenId tuple
        nftKeyTupleLookup[erc20Shares].nft = nft;
        nftKeyTupleLookup[erc20Shares].tokenId = tokenId;        
        
        // transfer the NFT asset from the issuer to this contract
        _escrow.hold(issuer, nft, tokenId);
        //ERC721 nftToken = ERC721(nft);
        //nftToken.safeTransferFrom(issuer, this, tokenId);
        
        // set the metadata fields    
        metadata.issuer = issuer;
        metadata.erc20Shares = erc20Shares;
        metadata.totalShares = numberOfSharesToIssue;

        // emit the appropriate event
        emit SharesBoundToNft(issuer, nft, tokenId, erc20, numberOfSharesToIssue);
    }
    
    function redeem(
        address redeemer,
        address erc20Shares, 
        uint amount
    ) 
        public
        returns (bool)
    {
        NftKeyTuple storage nftKeyTuple = nftKeyTupleLookup[erc20Shares];
        address nft = nftKeyTuple.nft;
        uint tokenId = nftKeyTuple.tokenId;
        
        IssuanceData storage data = lookup[nft][tokenId];

        // confirm that expected erc20 address matches the input (which also ensures there was a record for the key)
        require(data.erc20Shares == erc20Shares, "Shares address does not match");
        
        // confirm the amount sent is the total expected supply
        require(data.totalShares == amount, "You must send the entire token supply to redeem.");     
          
        ERC20 shares = ERC20(erc20Shares);

        // confirm that the total token supply is being transferred
        require(shares.totalSupply() == amount, "You must send the entire token supply to redeem.");

        // transfer erc20 shares from caller to this contract.  Will fail if no approval.
        shares.transferFrom(redeemer, this, amount);
        
        // unlock the NFT and transfer it to the caller
        _escrow.release(redeemer, nft, tokenId);
        //ERC721 nftToken = ERC721(nft);
        //nftToken.safeTransferFrom(this, redeemer, tokenId);
        
        // delete all metadata and lookup info as it is no longer needed - and saves gas costs
        expunge(nft, tokenId, erc20Shares);
        
        return true;
    }

    function findByNftAddressAndTokenId(
        address nft,
        uint tokenId
    )
        public
        view
        returns (address issuer, address erc20Shares, /*address voting,*/ uint totalShares)
    {
        require(nft != address(0), "Invalid NFT address.");
        IssuanceData memory data = lookup[nft][tokenId];
        return (data.issuer, data.erc20Shares, /*data.voting,*/ data.totalShares);
    }

    function findBySharesAddress(address erc20) 
        public 
        view 
        returns (address nft, uint tokenId) 
    {
        require(erc20 != address(0), "Invalid erc20 address.");
        NftKeyTuple memory tuple = nftKeyTupleLookup[erc20];
        return (tuple.nft, tuple.tokenId);
    }
    
    


    /* Private helper functions
    */
    function expunge(address nft, uint tokenId, address erc20Shares) private {
        delete lookup[nft][tokenId];
        delete nftKeyTupleLookup[erc20Shares];
    }
}