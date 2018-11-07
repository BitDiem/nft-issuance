pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/access/Roles.sol";
import "./access/ListMaintainerRole.sol";

/**
 * Contract to maintain a list of approved voting modules.  Ideally this would be 
 * managed by a governance layer, or a token curated registry.
 */
contract ApprovedModuleList is ListMaintainerRole {
   
    using Roles for Roles.Role;

    event ModuleAdded(address indexed votingModule);
    event ModuleRemoved(address indexed votingModule);

    Roles.Role private votingModules;

    function contains(address votingModule) public view returns (bool) {
        return votingModules.has(votingModule);
    }

    function add(address votingModule) public onlyListMaintainer {
        votingModules.add(votingModule);
        emit ModuleAdded(votingModule);
    }

    function remove(address votingModule) public onlyListMaintainer {
        votingModules.remove(votingModule);
        emit ModuleRemoved(votingModule);
    }

}