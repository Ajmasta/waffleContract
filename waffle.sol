//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//interface ERC721
interface IERC721{ 


    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;



    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;


    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
contract Raft  is VRFConsumerBaseV2{ 
      VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  uint32 callbackGasLimit = 600000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  2;

uint256[] public s_randomWords;
  uint256 public s_requestId;

  address s_owner;
  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }
    struct Raffle{
        uint256 ticketPrice;
        uint256 ticketAmount;
        uint256 deadline;
        address owner;
        uint256 raffleId; 
        address collection;
        uint256 nftId;
        uint256 minAmountToSell;
        bool raffled;
        bool claimed;
        uint256 winnerId;
      
    }
    Raffle[] public raffles;

    uint256 raffleId = 0;
    mapping(uint256=>address[]) public raffleToParticipants;
    mapping(address=>Raffle) ownerToRaffle;
    mapping(uint256 => Raffle) idToRaffle;
    mapping(address=>Raffle[]) userToJoinedRaffles;
    mapping(address=>Raffle[])userToCreatedRaffles;

    Raffle public activeRaffle;
    bool public raffleInProgress = false;
    
    // function that checks approveToTransfer to start the raffle
    function startRaffle(address _collection, uint256 _ticketPrice, uint256 _ticketAmount, uint256 _deadline,uint256 _nftId, uint256 _minAmountToSell) public {
        IERC721 collection = IERC721(_collection);
        require(collection.ownerOf(_nftId)==msg.sender,"You do not own the NFT");
        require(collection.isApprovedForAll(msg.sender,address(this)),"You need to approve this contract");
        
        Raffle memory newRaffle = Raffle(_ticketPrice,_ticketAmount, _deadline, msg.sender, raffleId,_collection, _nftId,_minAmountToSell,false,false,0);
        raffleId+=1;
        
        raffles.push(newRaffle);
        userToCreatedRaffles[msg.sender].push(newRaffle);
    }
    function joinRaffle(uint256 _raffleId, uint256 _ticketAmount) payable public {
      Raffle memory raffle = raffles[_raffleId];
      
      require(raffle.raffled == false,"This raffle has ended");
      require(msg.value==raffle.ticketPrice*_ticketAmount,"You need to pay the right amount");

      address[] storage listOfParticipants = raffleToParticipants[_raffleId];
     
      require(raffle.ticketAmount > listOfParticipants.length,"No more tickets!");
       for(uint256 i=1;i<=_ticketAmount;i++){
        listOfParticipants.push(msg.sender);
       }
       userToJoinedRaffles[msg.sender].push(raffle);

    }


  function claimWinnings(uint256 _raffleId) public {
    Raffle storage winningRaffle = raffles[_raffleId];
    address[] memory listOfParticipants = raffleToParticipants[winningRaffle.raffleId];

    require(winningRaffle.raffled==true,"this raffle has not been raffled yet");
    require(winningRaffle.claimed==false,"this raffle has already been claimed");

    winningRaffle.claimed=true;

    
    IERC721 nft = IERC721(winningRaffle.collection);
    nft.transferFrom(winningRaffle.owner,listOfParticipants[winningRaffle.winnerId],winningRaffle.nftId);

    uint256 totalCollected = winningRaffle.ticketPrice*listOfParticipants.length;
    payable(winningRaffle.owner).transfer(totalCollected);

  }

   /**
     * @notice function to start drawing the raffle
     *
     */
  function requestRandomWords(uint256 _raffleId) external  {
   
    
    Raffle storage selectedRaffle = raffles[_raffleId];

    require(raffleInProgress==false,"One raffle already being drawn, wait for your turn");
    require(msg.sender==selectedRaffle.owner,"You are not the owner of this raffle");
    require(block.timestamp > selectedRaffle.deadline,"It's too early.");
    require(selectedRaffle.raffled==false,"This raffle has already been raffled");

    raffleInProgress = true;
    activeRaffle = selectedRaffle;

    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  

  }

  /**
     * @notice function called by chainlink node to add random number to raffle
     *
     */
  function fulfillRandomWords(
    uint256,   
   uint256[] memory randomWords
  ) internal override  {
    s_randomWords = randomWords;
    uint256 randomNumber = s_randomWords[0];
     address[] memory listOfParticipants = raffleToParticipants[activeRaffle.raffleId];
    Raffle storage selectedRaffle = raffles[activeRaffle.raffleId];

    selectedRaffle.winnerId = randomNumber % listOfParticipants.length + 1;
    selectedRaffle.raffled = true;
    raffleInProgress=false;
  }

    /**
     * @notice functions to fetch data on raffles
     *
     */

    function returnRaffles() public view returns(Raffle [] memory ){
      return raffles;
    }
    function returnParticipants(uint256 _raffleId) public view returns(address [] memory){
      address[] memory participants = raffleToParticipants[_raffleId];
      return participants;
    }
    function returnUserTickets() public view returns(Raffle [] memory){
      Raffle [] memory userRaffles = userToJoinedRaffles[msg.sender];
      return userRaffles;
    }
      function returnUserRaffles() public view returns(Raffle [] memory){
      Raffle [] memory userRaffles = userToCreatedRaffles[msg.sender];
      return userRaffles;
    }


  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

}
