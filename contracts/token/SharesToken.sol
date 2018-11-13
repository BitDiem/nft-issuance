pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @title SharesToken
 * @dev A standard ERC20 token derived from Open Zeppelin's implementation - 
 * with the addition of an internal array to track all current shareholders.
 */
contract SharesToken is IERC20, ERC20, ERC20Detailed {

    uint8 private constant DECIMALS = 18;

    // the combination of the  mapping and array can be used to efficiently track all token holders
    mapping(address => uint256) private holderIndices;
    address[] private shareholders;

    event ShareholderAdded(address shareholder);
    event ShareholderRemoved(address shareholder);

    constructor(
        string name, 
        string symbol, 
        address holder,
        uint totalSupply
    ) 
        ERC20Detailed(name, symbol, DECIMALS) 
        public 
    {
        _mint(holder, totalSupply);
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);
        
        // add the to address to the list of shareholders if not already present
        addShareholder(to);
        removeShareholder(from);
    }

    // The following code comes from https://github.com/davesag/ERC884-reference-implementation

    /**
     *  The `transfer` function MUST NOT allow transfers to addresses that
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    /*function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        updateShareholders(to);
        pruneShareholders(msg.sender, value);
        return super.transfer(to, value);
    }*/

    /**
     *  The `transferFrom` function MUST NOT allow transfers to addresses that
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `from`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    /*function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
        updateShareholders(to);
        pruneShareholders(from, value);
        return super.transferFrom(from, to, value);
    }*/

    /**
     *  The number of addresses that own tokens.
     *  @return the number of unique addresses that own tokens.
     */
    function holderCount()
        public
        //onlyOwner
        view
        returns (uint)
    {
        return shareholders.length;
    }

    /**
     *  By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function holderAt(uint256 index)
        public
        //onlyOwner
        view
        returns (address)
    {
        require(index < shareholders.length);
        return shareholders[index];
    }

    /**
     *  If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param addr The address to add as a shareholder if it's not already.
     */
    function addShareholder(address addr)
        internal
    {
        if (holderIndices[addr] == 0) {
            holderIndices[addr] = shareholders.push(addr);
            emit ShareholderAdded(addr);
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param addr The address to prune if their balance will be reduced to 0.
     @  @dev see https://ethereum.stackexchange.com/a/39311
     */
     // First, commented out version is the original code from the erc884 reference implementation.
     // Second version is the improved version
    /*function pruneShareholders(address addr, uint256 value)
        internal
    {
        uint256 balance = _balances[addr] - value;
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
        // overwrite the addr's slot with the last shareholder
        shareholders[holderIndex] = lastHolder;
        // also copy over the index (thanks @mohoff for spotting this)
        // ref https://github.com/davesag/ERC884-reference-implementation/issues/20
        holderIndices[lastHolder] = holderIndices[addr];
        // trim the shareholders array (which drops the last entry)
        shareholders.length--;
        // and zero out the index for addr
        holderIndices[addr] = 0;
    }*/
    function removeShareholder(address addr)
        internal
    {
        if (balanceOf(addr) > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
        // overwrite the addr's slot with the last shareholder
        shareholders[holderIndex] = lastHolder;
        // also copy over the index (thanks @mohoff for spotting this)
        // ref https://github.com/davesag/ERC884-reference-implementation/issues/20
        holderIndices[lastHolder] = holderIndices[addr];
        // trim the shareholders array (which drops the last entry)
        shareholders.length--;
        // and zero out the index for addr
        holderIndices[addr] = 0;

        emit ShareholderRemoved(addr);
    }

}