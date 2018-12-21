pragma solidity ^0.4.24;

contract IssuanceOperationApprovable {

    event ApprovalForNft(
        address indexed owner,
        address indexed approved,
        address indexed nft,
        uint256 tokenId,
        bool isApproved
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed approved,
        bool isApproved
    );

    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (address => mapping (address => mapping (address => mapping (uint256 => bool)))) private _nftApprovals;

    /**
     * @dev 
     * @param approvee The address which will spend the funds.
     * @param value The amount of tokens to be spent.
    */
    function setApprovalForNft(
        address approvee, 
        address nft, 
        uint tokenId, 
        bool value
    ) 
        public 
    {
        require(approvee != address(0));

        _nftApprovals[msg.sender][approvee][nft][tokenId] = value;
        emit ApprovalForNft(msg.sender, approvee, nft, tokenId, value);
    }

    function setApprovalForAll(
        address approvee, 
        bool value
    ) 
        public 
    {
        require(approvee != address(0));

        _operatorApprovals[msg.sender][approvee] = value;
        emit ApprovalForAll(msg.sender, approvee, value);
    }

    function isApprovedForNft(
        address owner, 
        address caller, 
        address nft, 
        uint tokenId
    ) 
        public 
        view 
        returns (bool) 
    {
        return _nftApprovals[owner][caller][nft][tokenId];
    }

    function isApprovedForAll(
        address owner, 
        address caller
    ) 
        public 
        view 
        returns (bool) 
    {
        return _operatorApprovals[owner][caller];
    }

    function _isApprovedOrMessageSender(
        address owner,
        address nft,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        address caller = msg.sender;

        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
            caller == owner ||
            isApprovedForAll(owner, caller) ||
            isApprovedForNft(owner, caller, nft, tokenId)
        );
    }

}