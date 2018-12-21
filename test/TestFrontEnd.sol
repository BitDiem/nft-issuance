pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../contracts/issue/Issuance.sol";
import "../contracts/token/SharesToken.sol";
import "../contracts/frontend/IssuanceFrontEnd.sol";
import "../contracts/frontend/StandardTokenFactory.sol";
import "./mocks/MockNft.sol";

contract TestFrontEnd {

    function testIssuance() public {

        address issuer = address(this);

        MockNft nft = new MockNft();
        uint tokenId = 1;
        nft.mint(tokenId);

        uint numberOfShares = 10;

        Assert.equal(nft.ownerOf(tokenId), issuer, "Owner of token should be the issuer");

        Issuance issuance = Issuance(DeployedAddresses.Issuance());// new Issuance();

        // expect that the address of issuance and this contract are different
        // how?

        IssuanceFrontEnd fe = new IssuanceFrontEnd(issuance);

        // approve the issuance contract for transferring the NFT token
        nft.approve(issuance, tokenId);
        //nft.setApprovalForAll(issuance, true);


        // approve the frontend contract for being able to call the Issuance contract on behalf of the token owner
        issuance.setApprovalForNft(fe, nft, tokenId, true);
        //issuance.setApprovalForAll(fe, true);


        address tokenAddr = fe.issue(nft, tokenId, "FE-Token", "FET", numberOfShares, StandardTokenFactory.TokenType.ERC20);
        IERC20 token = IERC20(tokenAddr);
        (,,, address bank) = issuance.find(nft, tokenId);
        address tokenHolder = bank; // address(issuance);

        Assert.equal(nft.ownerOf(tokenId), tokenHolder, "Owner of token should now be the Issuance contract");

        // approve the issuance contract for transferring the shares tokens
        token.approve(issuance, 99999);

        fe.redeem(token, numberOfShares);

        Assert.equal(nft.ownerOf(tokenId), address(issuer), "Owner of token should now be the issuer");
    }
}