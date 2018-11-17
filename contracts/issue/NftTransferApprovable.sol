pragma solidity ^0.4.24;

contract NftTransferApprovable {

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
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
    */
    function setApprovalForNft(
        address spender, 
        address nft, 
        uint tokenId, 
        bool value
    ) 
        public 
    {
        require(spender != address(0));

        _nftApprovals[msg.sender][spender][nft][tokenId] = value;
        emit ApprovalForNft(msg.sender, spender, nft, tokenId, value);
    }

    function setApprovalForAll(
        address spender, 
        bool value
    ) 
        public 
    {
        require(spender != address(0));

        _operatorApprovals[msg.sender][spender] = value;
        emit ApprovalForAll(msg.sender, spender, value);
    }

    function isApprovedForNft(
        address owner, 
        address spender, 
        address nft, 
        uint tokenId
    ) 
        public 
        view 
        returns (bool) 
    {
        return _nftApprovals[owner][spender][nft][tokenId];
    }

    function isApprovedForAll(
        address owner, 
        address spender
    ) 
        public 
        view 
        returns (bool) 
    {
        return _operatorApprovals[owner][spender];
    }

    function _isApprovedOrMessageSender(
        address spender,
        address nft,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = msg.sender;

        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
            owner == spender ||
            isApprovedForAll(owner, spender) ||
            isApprovedForNft(owner, spender, nft, tokenId)
        );
    }

}