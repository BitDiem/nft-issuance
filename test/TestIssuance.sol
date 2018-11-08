pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../contracts/Issuance.sol";
import "../contracts/token/SharesToken.sol";
import "./mocks/MockNft.sol";

contract TestIssuance {

    function testIssuance() public {

        address issuer = address(this);

        MockNft nft = new MockNft();
        uint tokenId = 1;
        nft.mint(tokenId);

        Assert.equal(nft.ownerOf(tokenId), issuer, "Owner of token should be the issuer");

        // create a token representing shares, with 10 supply and entire supply held by this contract
        IERC20 token = new SharesToken("testName", "testSymbol", issuer, 10);

        Issuance issuance = new Issuance();

        // approve the issuance contract for transferring the NFT token
        nft.approve(issuance, tokenId);
        //nft.setApprovalForAll(issuance, true);

        issuance.issue(issuer, nft, tokenId, token, 10);

        Assert.equal(nft.ownerOf(tokenId), address(issuance), "Owner of token should now be the Issuance contract");
    }
}