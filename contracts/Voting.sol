pragma solidity ^0.4.24;

import "./ERC721.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./Issuance.sol";

/**
 * @title Voting
 * @dev Simple majority voting system that allows anyone to propose an offer for an NFT held within the Issuance shares system.  
 * Shareholders vote, votes are weighted by tokens held.
 */
contract Voting {

    using SafeMath for uint256;
  
    struct Proposal {
        address proposer;
        uint yay;
        uint nay;
        uint threshold;
        uint minimumVotesRequired;
        uint expiration;        // expiring block
        address paymentType;
        uint paymentAmount;
    }
    
    struct VoterBalance {
        address voter;
        uint totalVoted;
    }
    
    address _issuance;
    address _erc20;
    Proposal _currentProposal;
    VoterBalance[] _balances;
    
    event ProposalCreated(
        address proposer, 
        uint threshold, 
        uint minimumVotesRequired, 
        uint expiration, 
        address paymentType, 
        uint paymentAmount);

    event VoteReceived(address voter, bool vote, uint amount);

    event VoteRetracted(address voter, bool vote, uint amount);

    event ProposalAccepted(uint totalYay, uint totalNay);
    
    event ProposalRejected(uint totalYay, uint totalNay);
    
    constructor (address issuance, address erc20) public {
        _issuance = issuance;
        _erc20 = erc20;
    }
    
    /**
     * @dev Create a new proposal for transferring ownership of the underlying NFT to a user making the proposal.
     * @param proposer Who is offering this proposal.
     * @param threshold The amount of votes required to automatically accept or reject a proposal.
     * @param minimumVotesRequired The minimum number of votes required for a proposal to be accepted.
     * @param expiresIn In how many blocks will this vote expire - after which no further votes will be accepted.
     * @param paymentType the ERC20 token address of the proposed payment method.
     * @param proposer The amount of tokens offered as payment for the underlying NFT asset.
     * @return True if the proposal was recorded successfully, otherwise false.
     */
    function propose(
        address proposer,   // do we assume that message.sender is also the proposer?  If so, this would be unnecessary
        uint threshold,
        uint minimumVotesRequired,
        uint expiresIn,
        address paymentType,
        uint paymentAmount
    )
        public
        returns (bool)
    {
        require (_currentProposal.proposer == 0, "Only one proposal can be active at a time");
        require (proposer != address(0));
        require (expiresIn > 0);

        // escrow the payment amount for the input erc20 token
        ERC20 paymentContract = ERC20(paymentType);
        paymentContract.transferFrom(msg.sender, this, paymentAmount);  // will payment come from the caller or the proposer?

        // calculate expiration block
        uint expiration = block.number.add(expiresIn);

        // set variables for current proposal (assuming token transfer approval was granted so that transferFrom above worked)
        _currentProposal.proposer = proposer;
        _currentProposal.threshold = threshold;
        _currentProposal.minimumVotesRequired = minimumVotesRequired;
        _currentProposal.expiration = expiration;
        _currentProposal.paymentType = paymentType;
        _currentProposal.paymentAmount = paymentAmount;  
        
        // Fire "new proposal" event
        emit ProposalCreated(proposer, threshold, minimumVotesRequired, expiration, paymentType, paymentAmount);
        
        return true;
    }
    
    /**
     * @dev Vote on the current proposal, using some amount of voter's shares tokens balance.  Vote is binary - a simple "yes" or "no".
     * @param erc20 The ERC20 shares token address.  Used as a safety check to ensure the voter is voting with the right tokens.
     * @param vote Vote where "yes"/"no" corresponds with true/false.
     * @param amount The amount of shares to vote with, which will be transferred to this contract until voting ends.
     * @return True if the vote was recorded successfully, otherwise false.
     */
    function voteOnCurrentProposal(
        address erc20,  // is this necessary?
        bool vote,
        uint amount
    )
        public
        returns (bool)
    {
        require (_currentProposal.proposer != 0, "No active proposal");
        require (_erc20 == erc20);
        require (amount > 0, "Amount must be greater than zero");

        // check the state of the current proposal.  If it is not expired, then we can still vote on it
        require (checkProposalStatus(), "No active proposal");
        
        address voter = msg.sender;

        // transfer shares from the voter to this contract
        ERC20 token = ERC20(erc20);
        token.transferFrom(voter, this, amount);
        
        // update balance for this voter, so we can refund them correctly once voting is over
        updateBalance(voter, amount);
        
        if (vote == true)  recordYay(amount);
        else                recordNay(amount);
        
        // Fire "vote received" event
        emit VoteReceived(voter, vote, amount);
        
        return true;
    }
   
    /**
     * @dev Allows the user to retract their vote.  Mainly used to recover their token balance 
     * in the event they need to transfer their tokens for some other purpose aside from voting.
     * @param erc20 The ERC20 shares token address.  Used as a safety check to ensure the voter is voting with the right tokens.
     * @param vote Vote where "yes"/"no" corresponds with true/false.
     * @param amount The amount of shares to vote with, which will be transferred to this contract until voting ends.
     * @return True if the vote was retracted successfully, otherwise false.
     */ 
    function retractVote(
        address erc20,  // is this necessary?
        bool vote,
        uint amount
    )
        public
        returns (bool)
    {
        require (_currentProposal.proposer != 0, "No active proposal");
        require (_erc20 == erc20);
        require (amount > 0, "Amount must be greater than zero");

        // check the state of the current proposal.  If it is not expired, then we can still vote on it
        require (checkProposalStatus(), "No active proposal");
        
        address voter = msg.sender;

        // transfer shares from this contract back to the voter
        ERC20 token = ERC20(erc20);
        token.transferFrom(this, voter, amount);
        
        // update balance for this voter, so we can refund them correctly once voting is over
        // TODO: create the "retract" version of updateBalance(voter, _amount);
        
        if (vote == true)  retractYay(amount);
        else                retractNay(amount);
        
        // Fire "vote retracted" event
        emit VoteRetracted(voter, vote, amount);
        
        return true;
    }
    
    /**
     * @dev Function is intended to be used as a "hearbeat" to check whether the voting period has expired.  
     * If the voting period has expired, a final tally occurs to check whether a proposal passed.
     * @return True if voting is still open, false if it has ended.
     */
    function checkVoteStatus() public returns (bool) {
        require (_currentProposal.proposer != 0, "No active proposal");
        return checkProposalStatus();
    }




    /* Private helper functions
    -----------------------------------------------------------------------------
    */
    
    function proposalIsNotExpired() private view returns (bool) {
        return (_currentProposal.expiration > block.number);
    }
    
    // check to see if proposal is expired.  If it is, then: 
    // 1) check to see if majority vote wins, 
    // 2) transfer tokens back to voters, 
    // 3)  cleanup by deleting all variables associated with current proposal.
    function checkProposalStatus() private returns (bool) {
        if (proposalIsNotExpired())
            return true;
        
        checkForMajorityVote();
        transferTokensBackToVoters();
        delete _currentProposal;
        delete _balances;
        return false;
    }
    
    // check for a simple majority of yes/no votes, provided the total number of votes (either way) is greather than the minimum amount required
    function checkForMajorityVote() private {
        if ((_currentProposal.yay > _currentProposal.nay) &&
            (_currentProposal.yay > _currentProposal.minimumVotesRequired))
                acceptCurrentProposal();
        
        else if ((_currentProposal.nay > _currentProposal.yay) &&
            (_currentProposal.nay > _currentProposal.minimumVotesRequired))
                rejectCurrentProposal();
    }
    
    // Update the balance of shares voted on for a given voter
    // TODO: improve search for voter by implementing a Dictionary data structure
    function updateBalance(address voter, uint amount) private {
        // find the matching entry for the input voter
        for (uint i = 0; i < _balances.length; i++) {
            if (_balances[i].voter == voter)
                break;
        }
        
        // if we iterated through the list without finding the voter, he's new so add him to the list
        if (i == _balances.length) {
            VoterBalance memory vb = VoterBalance(voter, 0);
            _balances.push(vb);
        }
        
        _balances[i].totalVoted = _balances[i].totalVoted.add(amount);
    }
    
    function recordYay(uint amount) private {
        _currentProposal.yay = _currentProposal.yay.add(amount);
        
        // tally "Yes" votes
        if (_currentProposal.yay > _currentProposal.threshold)
            acceptCurrentProposal();        
    }
    
    function retractYay(uint amount) private {
        _currentProposal.yay = _currentProposal.yay.sub(amount);
    }
    
    function recordNay(uint amount) private {
        _currentProposal.nay = _currentProposal.nay.add(amount);
        
        // tally "No" votes
        if (_currentProposal.nay > _currentProposal.threshold)
            rejectCurrentProposal();        
    }
    
    function retractNay(uint amount) private {
        _currentProposal.nay = _currentProposal.nay.sub(amount);
    }
    
    function acceptCurrentProposal() private {
        // Fire a "proposal accepted" event
        emit ProposalAccepted(_currentProposal.yay, _currentProposal.nay);
        
        // TODO: pay out payment type to each address in proportion to the holdings of each shareholder   
        // TODO: instead of transfer tokens back to voters, burn the tokens
        // TODO: NOTE THAT NEITHER OF THE ABOVE WILL BE POSSIBLE FROM WITHIN THIS CONTRACT.  WILL HAVE TO CALL INTO THE Issuance CONTRACT
        // Transfer the payment tokens to the issuance contract
        ERC20 paymentContract = ERC20(_currentProposal.paymentType);
        paymentContract.transferFrom(this, _issuance, _currentProposal.paymentAmount);

        //Issuance issuance = Issuance(_issuance);
        // need an erc20 token that outputs an iterable list of addresses and percentages

        delete _currentProposal;
        delete _balances;
    }
    
    function rejectCurrentProposal() private {
        // Fire a "proposal rejected" event
        emit ProposalRejected(_currentProposal.yay, _currentProposal.nay);
        
        transferTokensBackToVoters();
        delete _currentProposal;
        delete _balances;
    }
    
    function transferTokensBackToVoters() private {
        ERC20 token = ERC20(_erc20);
        
        for (uint i = 0; i < _balances.length; i++) {
            token.transferFrom(this, _balances[i].voter, _balances[i].totalVoted);
        }       
    }
}