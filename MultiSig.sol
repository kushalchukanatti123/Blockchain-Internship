pragma solidity 0.8.0;

contract MultiSig {

    event SubmitTransaction(
        address indexed sender,
        uint256 indexed txIndex,
        address indexed tokenOwner,
        address to,
        uint256 _tokenId,
        string data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address tokenOwner; //LET THE TOKEN BE IN THE NAME OF SINGLE OWNER. 
                            
                            //TODO: CREATE A JOINT MAP WHICH INCLUDES OTHER OWNERS OF THE TOKEN, 
                            //AND WHILE CALLING THIS CONTRACT GET ALL THE OTHER OWNERS FROM THERE AND PROVIDE IT TO THE CONSTRUCTOR
        address to;
        uint256 tokenId;
        string data;
        bool executed;
        uint256 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "transaction already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }
    
    
    function submitTransaction(address _tokOwner,address _to, uint256 _tokenId, string memory _data)
        public
        onlyOwner
    {
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({
            tokenOwner: _tokOwner,
            to: _to,
            tokenId:_tokenId,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));    

        emit SubmitTransaction(msg.sender, txIndex,_tokOwner, _to,_tokenId, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "not enough confirmations, cannot execute transaction"
        );
        
        

        //THE ACTION OF TRANSFERING THE ASSET OR CARD NEEDS TO BE DONE HERE, SEE THAT EVEN THE OTHER OWNER WILL BE ABLE TO TRANSFER THE ASSET HERE

        transaction.executed = true;

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "Cannot revoke, as you havent confirmed the transaction yet");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (address tokenOwner,address to,uint256 tokenId,string memory data,bool executed,uint256 numConfirmations)
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.tokenOwner,
            transaction.to,
            transaction.tokenId,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}
