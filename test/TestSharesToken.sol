pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/token/SharesToken.sol";

contract TestSharesToken {

    function testSharesToken() public {

        address issuer = address(this);
        uint numberOfShares = 10;

        SharesToken token = new SharesToken("testName", "testSymbol", issuer, numberOfShares);

        Assert.equal(token.balanceOf(issuer), numberOfShares, "Incorrect token balance");
        Assert.equal(token.holderCount(), 1, "Incorrect holder count");
        Assert.equal(token.holderAt(0), issuer, "Incorrect token holder");

        address newGuy = msg.sender;
        
        //token.approve(issuer, 9999);
        token.transfer(newGuy, 4);

        Assert.equal(token.balanceOf(issuer), 6, "Incorrect token balance 2");
        Assert.equal(token.balanceOf(newGuy), 4, "Incorrect token balance 3");
        Assert.equal(token.holderCount(), 2, "Incorrect holder count 2");
        Assert.equal(token.holderAt(1), newGuy, "Incorrect token holder 2");

        token.transfer(newGuy, 6);

        Assert.equal(token.balanceOf(issuer), 0, "Incorrect token balance 3");
        Assert.equal(token.balanceOf(newGuy), 10, "Incorrect token balance 4");
        Assert.equal(token.holderCount(), 1, "Incorrect holder count 3");
        Assert.equal(token.holderAt(0), newGuy, "Incorrect token holder 3");     
    }
}