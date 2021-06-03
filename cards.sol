pragma solidity ^0.6.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC1155/ERC1155.sol";


contract Cards is ERC1155 {
    uint256 tokenCounter;
    address owner;
    
    // tokenid=>IPFS hash
     mapping(uint256=>string) public tokenURIs;
   
    modifier onlyOwner() {
         //allows only the owner
        require(msg.sender == owner,"This operation is allowed only for the owner of the contract");
        _;
    }

    constructor() public ERC1155("https://ipfs.io/ipfs/{id}.json") {
        tokenCounter=0;
        //deployer of the contract is made as the owner of the contract
        owner = msg.sender;
    }
    
    
    function createNFT(address _to,string memory _ipfsHash) external onlyOwner returns(uint256) {
        

        //the amount is set to 1 as we are minting an NFT
        _mint(_to, tokenCounter, 1,"");
        tokenURIs[tokenCounter] = _ipfsHash;
        uint256 temp = tokenCounter;
        tokenCounter=tokenCounter+1;
        return temp;
    }
    
    function transferNFT(address _from, address _to, uint256 _tokenId) public {
        //assuring that the _from address owns the asset
        require(balanceOf(_from,_tokenId)!=0,"You currently do not own the asset you tring to trade");
        
        //assuring that from address and the address performing the address are same
        require(_from==msg.sender,"From and sender address are not same");
        
        //the amount is set to 1 as we are trading an NFT
        safeTransferFrom(_from, _to,_tokenId, 1, "");
    }
    
}
