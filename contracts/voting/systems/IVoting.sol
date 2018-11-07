pragma solidity ^0.4.24;

/**
 * @title IVoting interface
 * @dev Encapsulates commonality between different voting systems
 */
interface IVoting {

    function checkVoteStatus() external returns (bool);

}
