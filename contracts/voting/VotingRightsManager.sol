
pragma solidity ^0.4.24;

import "./Voting.sol";
import "../ERC721.sol";

contract VotingRightsManager {

    mapping (address => mapping (uint => Voting)) lookup;
    mapping (address => bool) approvedVotingModules;

    function setVotingManager(
        address nft, 
        uint tokenId, 
        address voting
    ) 
        public
        returns (bool)
    {
        require(nft != address(0));
        require(voting != address(0));

        // the voting module must be on the list of approved modules
        require (approvedVotingModules[voting] == true, "That address is not an approved voting module");

        Voting votingContract = lookup[nft][tokenId];
        require (address(votingContract) != address(0), "no matching metadata");

        // Check to see if there is an active vote.  We only allow re-assigning of the voting manager if there's no active vote.
        require (votingContract.checkVoteStatus() == false, "Vote status must be false (non-active)");

        // Approve the voting contract for transferring the NFT out?  This might be a bad idea.  Might need to invert this control
        ERC721 nftContract = ERC721(nft);
        nftContract.approve(voting, tokenId);
    }

    function distributeProposal(address nft, uint tokenId/*, address paymentType, uint paymentAmount*/) public view
    {    
        Voting votingContract = lookup[nft][tokenId];

        require(msg.sender == address(votingContract));

        // loop through shares owners, distribute paymentType accordingly and in proportion
    }
}