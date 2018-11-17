pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../utils/ERC721Utils.sol";
import "./NftTransferApprovable.sol";
import "./IERC721Receivable.sol";

/**
 * @title Issuance
 * @dev Allows one to associate an ERC20 token with a unique non-fungible ERC721 token, escrowing the latter.
 */
contract Issuance is NftTransferApprovable, IERC721Receivable  /* IERC721Receiver */{

    using ERC721Utils for IERC721;
    
    address private _escrow;
    
    // map of nft and token id to Issuance metadata
    mapping (address => mapping (uint => IssuanceData)) private lookup;
    
    // map of ERC20 addresses to corresponding NFT unique id tuple
    mapping (address => NftKeyTuple) private nftKeyTupleLookup;
    
    event NftLocked(address issuer, address nft, uint tokenId, address erc20, uint totalShares);
    event NftReleased(address issuer, address nft, uint tokenId, address erc20, uint totalShares);
    event EscrowAddressChanged(address escrow);
    
    // for a unique NFT-tokenId tuple, we store data on the issuer, the erc20 address, and the totalShares
    struct IssuanceData {
        address issuer;
        address erc20;
        uint totalShares;
    }
    
    struct NftKeyTuple {
        address nft;
        uint tokenId;
    }

    constructor () public {
        _setEscrow(address(this));
    }

    /**
     * @dev Issue shares for an NFT token.  Issuance will bind an ERC721 and ERC20 pair to each other, while escrowing the NFT token.
     * @param issuer The owner of the NFT token.
     * @param nft The address of the NFT token.
     * @param tokenId The id of the unique NFT token.
     * @param erc20 The address of the ERC20 token to be bound to the NFT token.
     * @param totalShares The total number of shares issued.
     * @return True if the NFT and shares were linked/bound successfully.
     */
    function issue(
        address issuer,
        address nft, 
        uint tokenId,
        address erc20,
        uint totalShares    
    )
        public
    {
        // all input addresses must be nonzero
        require(issuer != address(0), "Invalid issuer address");
        require(nft != address(0), "Invalid NFT address.");
        require(erc20 != address(0), "Invalid erc20 address.");

        // ensure approval
        require(isApprovedForNft(issuer, msg.sender, nft, tokenId), "Issuance approval required");

        // number of shares to issue must be at least 1
        require(totalShares > 0, "Number of shares to issue must be greater than zero.");

        // cast addresses to appropriate token types
        IERC20 erc20Token = IERC20(erc20);
        IERC721 nftToken = IERC721(nft);

        // lookup existing metadata for the nft-tokenId tuple
        IssuanceData storage metadata = lookup[nft][tokenId];

        // only one mapping between an NFT and erc20 shares is valid at a time.
        require(metadata.issuer == address(0), "Shares are already issued against this NFT.");

        // ensure the total supply of share tokens match the expected amount
        require(totalShares == erc20Token.totalSupply(), "ERC20 total supply does not match the expected amount.");

        // OPTIONAL: require the issuer owns the total supply of shares
        //require(totalShares == erc20Shares.balanceOf(issuer))

        // ensure that this contract has approval to transfer the NFT on behalf of the issuer
        // QUESTION: is this necessary?  or should we let the call to 'safeTransferFrom' fail naturally if approval was not set?
        require(nftToken.isApprovedOrOwner(address(this), tokenId), "Transfer approval required.");

        // transfer the NFT asset from the issuer to this contract
        nftToken.safeTransferFrom(issuer, _escrow, tokenId);
        //nftToken.transferFrom(issuer, _escrow, tokenId);

        // map from the erc20 address to the nft-tokenId tuple
        nftKeyTupleLookup[erc20].nft = nft;
        nftKeyTupleLookup[erc20].tokenId = tokenId;        
         
        // set the metadata fields    
        metadata.issuer = issuer;
        metadata.erc20 = erc20;
        metadata.totalShares = totalShares;

        // emit the appropriate event
        emit NftLocked(issuer, nft, tokenId, erc20, totalShares);
    }
    
    function redeem(
        address redeemer,
        address erc20, 
        uint amount
    ) 
        public
    {
        (address nft, uint tokenId) = find(erc20);
        (,, uint totalShares) = find(nft, tokenId);   
        
        // cast addresses to appropriate token types
        IERC20 erc20Token = IERC20(erc20);
        IERC721 nftToken = IERC721(nft);

        // confirm that the total token supply is being transferred, and that the total supply is consistent everywhere
        require(totalShares == amount, "You must send the entire token supply to redeem.");
        require(totalShares == erc20Token.totalSupply(), "You must send the entire token supply to redeem.");

        // Check and require for approval for the amount of shares to be transfereed
        // QUESTION: is this necessary?  or should we let the call to 'transferFrom' fail naturally if approval was not set?    
        require (erc20Token.allowance(redeemer, address(this)) >= amount);

        // Check approval for transferring the NFT to the redeemer
        // QUESTION: is this necessary?  or should we let the call to 'safeTransferFrom' fail naturally if approval was not set?    
        require(nftToken.isApprovedOrOwner(address(this), tokenId), "Transfer approval required.");

        // transfer erc20 shares from caller to this contract.  Will fail if no approval.
        erc20Token.transferFrom(redeemer, _escrow, amount);
        
        // unlock the NFT and transfer it to the caller
        // QUESTION: call safeTransferFrom or normal transferFrom?  Do we assume the redeemer can accept the NFT?
        //nftToken.safeTransferFrom(_escrow, redeemer, tokenId);
        nftToken.transferFrom(_escrow, redeemer, tokenId);
        
        // delete all metadata and lookup info as it is no longer needed - and saves gas costs
        expunge(nft, tokenId, erc20);

        emit NftReleased(redeemer, nft, tokenId, erc20, totalShares);
    }

    function find(
        address nft,
        uint tokenId
    )
        public
        view
        returns (address issuer, address erc20, uint totalShares)
    {
        require(nft != address(0), "Invalid NFT address.");
        IssuanceData memory data = lookup[nft][tokenId];
        return (data.issuer, data.erc20, data.totalShares);
    }

    function find(address erc20) 
        public 
        view 
        returns (address nft, uint tokenId) 
    {
        require(erc20 != address(0), "Invalid erc20 address.");
        NftKeyTuple memory tuple = nftKeyTupleLookup[erc20];
        return (tuple.nft, tuple.tokenId);
    }




    /* Private and internal helper functions
    */
    function expunge(address nft, uint tokenId, address erc20) private {
        delete lookup[nft][tokenId];
        delete nftKeyTupleLookup[erc20];
    }

    function _setEscrow(address escrow) internal {
        require (escrow != address(0));
        require (escrow != _escrow);

        _escrow = escrow;
        emit EscrowAddressChanged(escrow);
    }
}