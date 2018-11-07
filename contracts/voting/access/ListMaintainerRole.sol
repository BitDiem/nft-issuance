pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/access/Roles.sol";

contract ListMaintainerRole {
   
    using Roles for Roles.Role;

    event ListMaintainerAdded(address indexed account);
    event ListMaintainerRemoved(address indexed account);

    Roles.Role private listMaintainers;

    constructor() internal {
        _addListMaintainer(msg.sender);
    }

    modifier onlyListMaintainer() {
        require (listMaintainers.has(msg.sender), "Not a list maintainer.");
        _;
    }

    function addListMaintainer(address account) public onlyListMaintainer {
        _addListMaintainer(account);
    }

    function renounceMinter() public {
        _removeListMaintainer(msg.sender);
    }    

    function _addListMaintainer(address account) internal onlyListMaintainer {
        listMaintainers.add(account);
        emit ListMaintainerAdded(account);
    }

    function _removeListMaintainer(address account) internal onlyListMaintainer {
        listMaintainers.remove(account);
        emit ListMaintainerRemoved(account);
    }

}