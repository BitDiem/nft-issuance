pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @title SharesToken
 * @dev A standard ERC20 token inheriting from Open Zeppelin's implementation - 
 * with the addition of an internal array to track token holders.
 */
contract ERC20Enumerable is IERC20, ERC20 {

    // the combination of the  mapping and array can be used to efficiently track all token holders
    mapping(address => uint) private accountToIndexMap;
    address[] private accounts;

    event AccountAdded(address account);
    event AccountRemoved(address account);

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        super._transfer(from, to, value);
        
        _addAccount(to);
        _removeAccount(from);
    }

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param value The amount that will be created.
    */
    function _mint(address account, uint256 value) internal {
        super._mint(account, value);

        _addAccount(account);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal {
        super._burn(account, value);
        
        _removeAccount(account);
    }

    // The following code comes from https://github.com/davesag/ERC884-reference-implementation

    /**
     *  The number of addresses that own tokens.
     *  @return the number of unique addresses that own tokens.
     */
    function accountsCount()
        public
        view
        returns (uint)
    {
        return accounts.length;
    }

    /**
     *  By counting the number of token accounts using `accountsCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  Throws if `index >= accountsCount()`.
     *
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function accountAt(uint256 index)
        public
        view
        returns (address)
    {
        require(index < accountsCount());
        return accounts[index];
    }

    /**
     *  Adds an address to the accounts list if not already present, and if the balance is greater than zero.
     *  NOTE: the stored index is actually the array length (i.e. offset by 1) 
     *  due to the necessity of having the default value of zero for unset values.
     */
    function _addAccount(address addr) internal
    {
        // if there is no index matching this address and the balance of the address is greater than zero, then add it
        if (accountToIndexMap[addr] == 0 && balanceOf(addr) > 0) {
            accountToIndexMap[addr] = accounts.push(addr);
            emit AccountAdded(addr);
        }
    }

    /**
     *  Removes an account if the account holder's balance is 0.
     */
    function _removeAccount(address accountToDelete)
        internal
    {
        if (balanceOf(accountToDelete) > 0) {
            return;
        }

        // get the last item in the array (both index and item)
        uint lastAccountIndex = accounts.length - 1;
        address lastAccount = accounts[lastAccountIndex];

        // get the index of the item to be deleted
        //uint deleteIndex = accountToIndexMap[accountToDelete];
        uint deleteIndex = accountToIndexMap[accountToDelete] - 1;  // with offset adjustment

        // swap the last item into the item to be deleted in the array
        accounts[deleteIndex] = lastAccount;

        // delete the last item from the array and trim the array size
        accounts[lastAccountIndex] = 0;
        accounts.length--;

        // update the map for the last element
        accountToIndexMap[lastAccount] = deleteIndex;

        // delete the map for the element that was removed
        accountToIndexMap[accountToDelete] = 0;

        emit AccountRemoved(accountToDelete);
    }
}