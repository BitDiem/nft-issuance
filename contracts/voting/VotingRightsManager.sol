
pragma solidity ^0.4.24;

import "./systems/IVoting.sol";
import "./ApprovedModuleList.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

contract VotingRightsManager {

    using Roles for Roles.Role;

    mapping (address => mapping (uint => IVoting)) private lookup;
    ApprovedModuleList private _approvedModuleList;
    
    // who can set the voting manager?  anyone! but the proposed module must be on an approved list
    function setVotingManager(
        address nft, 
        uint tokenId, 
        IVoting votingModule
    ) 
        public
        returns (bool)
    {
        require(nft != address(0));
        require(address(votingModule) != address(0));  // is this check necessary?

        // the proposed voting module must be on the list of approved modules
        require (_approvedModuleList.contains(address(votingModule)), "That address is not an approved voting module");

        // ensure the proposed voting module is not in an active vote
        require (votingModule.checkVoteStatus() == false, "Vote status must be false (non-active)");

        // 1. check for an existing voting module contract for this nft
        // 2. if there is a match, then check whether there is an active vote on the existing voting module
        // 3. We only allow re-assigning of the voting manager if there's no active vote.
        IVoting currentModule = lookup[nft][tokenId];
        if (address(currentModule) != address(0)) {
            require (currentModule.checkVoteStatus() == false, "Vote status must be false (non-active)");
        }

        // associate the proposed module with the nft-tokenId unique tuple
        lookup[nft][tokenId] = votingModule;

        // Approve the voting contract for transferring the NFT out?  This might be a bad idea.  Might need to invert this control
        //IERC721 nftContract = IERC721(nft);
        //nftContract.approve(voting, tokenId);
    }

    function getVotingManager(address nft, uint tokenId) public view returns (IVoting) {
        return lookup[nft][tokenId];
    }

    /*function distributeProposal(address nft, uint tokenId, address paymentType, uint paymentAmount) public view
    {    
        Voting votingContract = lookup[nft][tokenId];

        require(msg.sender == address(votingContract));

        // loop through shares owners, distribute paymentType accordingly and in proportion
    }*/
}