/* TESTING ONLY */

// IMPORTANT
// ------------------------------------------------------
// The LotteryAnvil contract is for local testing on Anvil because:
//
// Anvil Limitation: 
//    Anvil doesn't fully support block.prevrandao, which is used in the 
//    main Lottery contract for randomness generation. 
//    On Anvil, block.prevrandao always returns 0, which would break 
//    the Lottery's randomness mechanism.

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./libraries/PietrzakLibrary.sol";
import "./VDFPietrzak.sol";
import "./NFTPrize.sol";

/**
 * @title LotteryAnvil
 * @dev Implements a decentralized lottery system with VDF-based randomness and NFT prizes
 * @dev This is for testing purposes only. We use predfined values for block.prevrandao
 */
contract LotteryAnvil is Ownable, ReentrancyGuard {
    using BigNumbers for BigNumber;

    // Enums
    enum Difficulty { Easy, Medium, Hard }
    enum GameStatus { InPlay, Drawing, Completed }

    /**
     * @dev Struct containing basic game information
     */
    struct GameBasicInfo {
        uint256 gameId;
        GameStatus status;
        uint256 prizePool;
        uint256 numberOfWinners;
        uint256[4] winningNumbers;
    }

    /**
     * @dev Struct containing detailed game information
     */
    struct GameDetailedInfo {
        uint256 gameId;
        GameStatus status;
        uint256 prizePool;
        uint256 numberOfWinners;
        uint256 goldWinners;
        uint256 silverWinners;
        uint256 bronzeWinners;
        uint256[4] winningNumbers;
        Difficulty difficulty;
        uint256 drawInitiatedBlock;
        uint256 randaoBlock;
        uint256 randaoValue;
        uint256[3] payouts;
    }

    // Contracts
    VDFPietrzak public vdfContract;
    NFTPrize public immutable nftPrize;

    // Constants
    uint256 private constant BASIS_POINTS = 10000;
    uint256 public constant GOLD_PERCENTAGE = 6000;
    uint256 public constant SILVER_PLACE_PERCENTAGE = 2500;
    uint256 public constant BRONZE_PLACE_PERCENTAGE = 1400;
    uint256 public constant FEE_PERCENTAGE = 100;
    uint256 public constant FEE_MAX_IN_ETH = 100 ether;
    uint256 public constant EASY_MAX = 50;
    uint256 public constant EASY_ETHERBALL_MAX = 5;
    uint256 public constant MEDIUM_MAX = 100;
    uint256 public constant MEDIUM_ETHERBALL_MAX = 10;
    uint256 public constant HARD_MAX = 150;
    uint256 public constant HARD_ETHERBALL_MAX = 15;
    uint256 public constant DRAW_MIN_PRIZE_POOL = 500 ether;
    uint256 public constant DRAW_MIN_TIME_PERIOD = 1 weeks;
    uint256 public constant DRAW_DELAY_SECURITY_BUFFER = 128; // ~4 epoch delay 

    // State variables
    address public feeRecipient;
    uint256 public ticketPrice;
    uint256 public currentGameNumber;
    uint256 public lastDrawTime;
    uint256 public consecutiveJackpotGames;
    uint256 public consecutiveNonJackpotGames;
    Difficulty public newDifficulty;
    uint256 public newDifficultyGame;
    uint256 public newTicketPrice;
    uint256 public newTicketPriceGameNumber;
    address public newVDFContract;
    uint256 public newVDFContractGameNumber;

    uint256 public constant PREVRANDAO_COUNT = 29;
    uint256[PREVRANDAO_COUNT] public prevrandaoValues;
    uint256 public currentIndex;

    // Mappings
    mapping(uint256 => uint256) public gameStartBlock;
    mapping(uint256 => Difficulty) public gameDifficulty;
    mapping(uint256 => uint256) public gamePrizePool;
    mapping(uint256 => uint256[4]) public gameWinningNumbers;
    mapping(uint256 => uint256[3]) public gamePayouts;
    mapping(address => mapping(uint256 => uint256)) public playerTicketCount;
    mapping(uint256 => mapping(bytes32 => uint256)) public goldTicketCounts;
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public goldTicketOwners;
    mapping(uint256 => mapping(bytes32 => uint256)) public silverTicketCounts;
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public silverTicketOwners;
    mapping(uint256 => mapping(bytes32 => uint256)) public bronzeTicketCounts;
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) public bronzeTicketOwners;
    mapping(uint256 => bool) public gameDrawInitiated;
    mapping(uint256 => uint256) public gameRandomValue;
    mapping(uint256 => uint256) public gameRandomBlock;
    mapping(uint256 => bool) public gameVDFValid;
    mapping(uint256 => bool) public gameDrawCompleted;
    mapping(uint256 => mapping(address => bool)) public prizesClaimed;
    mapping(uint256 => uint256) public gameDrawnBlock;
    mapping(uint256 => mapping(address => bool)) public hasClaimedNFT;

    // Events
    event TicketPurchased(address indexed player, uint256 gameNumber, uint256[3] numbers, uint256 etherball);
    event TicketsPurchased(address indexed player, uint256 gameNumber, uint256 ticketCount);
    event DrawInitiated(uint256 gameNumber, uint256 targetSetBlock);
    event RandomSet(uint256 gameNumber, uint256 random);
    event VDFProofSubmitted(address indexed submitter, uint256 gameNumber);
    event WinningNumbersSet(uint256 indexed gameNumber, uint256 number1, uint256 number2, uint256 number3, uint256 etherball);
    event DifficultyChanged(uint256 gameNumber, Difficulty newDifficulty);
    event TicketPriceChangeScheduled(uint256 newPrice, uint256 effectiveGameNumber);
    event ExcessPrizePoolTransferred(uint256 fromGame, uint256 toGame, uint256 amount);
    event GamePrizePayoutInfo(uint256 gameNumber, uint256 goldPrize, uint256 silverPrize, uint256 bronzePrize);
    event FeeRecipientChanged(address newFeeRecipient);
    event PrizeClaimed(uint256 gameNumber, address player, uint256 amount);
    event NFTMinted(address indexed winner, uint256 indexed tokenId, uint256 indexed gameNumber);

    /**
     * @dev Constructor to initialize the Lottery contract
     * @param _vdfContractAddress Address of the VDFPietrzak contract
     * @param _nftPrizeAddress Address of the NFTPrize contract
     * @param _feeRecipient Address to receive fees
     */
    constructor(address _vdfContractAddress, address _nftPrizeAddress, address _feeRecipient) Ownable(msg.sender) {
        vdfContract = VDFPietrzak(_vdfContractAddress);
        nftPrize = NFTPrize(_nftPrizeAddress);
        ticketPrice = 0.1 ether;
        currentGameNumber = 1;
        gameDifficulty[currentGameNumber] = Difficulty.Easy;
        gameStartBlock[currentGameNumber] = block.number;
        lastDrawTime = block.timestamp;
        feeRecipient = _feeRecipient;

        prevrandaoValues[0] = 51049764388387882260001832746320922162275278963975484447753639501411130604681;
        prevrandaoValues[1] = 114647039150845253957106505659935793700741113189057202690540750438316827384848;
        prevrandaoValues[2] = 2656751508725187512486344122081204096368588122458517885621621007542366135775;
        prevrandaoValues[3] = 96618837226557606533137319610808329371780981598490822395441686749465502125142;
        prevrandaoValues[4] = 51434773657427415913027395301743798367869859907808600986758584585820106414285;
        prevrandaoValues[5] = 77199305852763991619765381452581945440280507230326453723346245677861653471063;
        prevrandaoValues[6] = 59990989837271091833382273688356937268795413672166946267660876871642195009438;
        prevrandaoValues[7] = 36676468656620308621211797666091354935984711877239173080112984515828038939051;
        prevrandaoValues[8] = 85697561369555299673517896277053419839231953934365698570431571823210297535292;
        prevrandaoValues[9] = 22517270229045003403001631809106535382982165988669329928144820079709611988034;
        prevrandaoValues[10] = 62040869921184974299683266977024177882617168160436995017339782279188958518568;
        prevrandaoValues[11] = 3742299576539977290353696032329569160429005173641040289439272819914257924048;
        prevrandaoValues[12] = 63749009331939910965282487505685731590652579266490021080961931679540086165062;
        prevrandaoValues[13] = 56794684067659848569949081870506295711490180170142117020965104265720263715714;
        prevrandaoValues[14] = 29594873761378778644957129285274086977318519009986584307007614122433751894707;
        prevrandaoValues[15] = 4500889233782608779799240686613350252512216476878923483501834892110225407209;
        prevrandaoValues[16] = 82411683116184644398436276416130226034054239508378028249195514431512028775612;
        prevrandaoValues[17] = 39465968593106643096084390312555437936097007607854184333644335743307192651075;
        prevrandaoValues[18] = 16926355081554932293127263620941454350188791613098925998296098861142719546412;
        prevrandaoValues[19] = 21661501667492044690012531394095317909416678194034192824917750098850207662593;
        prevrandaoValues[20] = 68129622304463926526727147325872886634441290560104916576475931165817718995199;
        prevrandaoValues[21] = 17367288974305421534987006751354799839325204778391789618277872660510084655726;
        prevrandaoValues[22] = 56026316513409516298338045794918197379242969239455247886024559086502838373883;
        prevrandaoValues[23] = 49403740388806625499641916536254761326065661663768618264521062745899599749617;
        prevrandaoValues[24] = 69915517736187644398815546146017020594092559464580824474964452414653604092879;
        prevrandaoValues[25] = 14608515538465303303881690003876779095180178128795528288780197331152497466148;
        prevrandaoValues[26] = 71335656787318350770615992927401593964805269175834534977509736236758395043458;
        prevrandaoValues[27] = 16295206386904369430685671792219467425088086964832939809888007942329494854936;
        prevrandaoValues[28] = 100983649657646566905723616094317458225903911725934304773286517195169330207570;
    }

    /**
     * @dev Allows users to buy multiple lottery tickets (100 max)
     * @param tickets Array of ticket numbers (4 numbers per ticket)
     */
    function buyTickets(uint256[4][] calldata tickets) external payable nonReentrant {
        uint256 ticketCount = tickets.length;
        require(ticketCount > 0 && ticketCount <= 100, "Invalid ticket count");
        require(msg.value == ticketPrice * ticketCount, "Incorrect total price");

        for (uint256 i = 0; i < ticketCount;) {
            _processSingleTicketPurchase([tickets[i][0], tickets[i][1], tickets[i][2]], tickets[i][3]);
            unchecked { ++i; }
        }

        playerTicketCount[msg.sender][currentGameNumber] += ticketCount;
        emit TicketsPurchased(msg.sender, currentGameNumber, ticketCount);
    }

    /**
     * @dev Internal function to process a single ticket purchase
     * @param numbers Array of 3 main numbers
     * @param etherball The etherball number
     */
    function _processSingleTicketPurchase(uint256[3] memory numbers, uint256 etherball) internal {
        require(_validateNumbers(numbers, etherball, currentGameNumber), "Invalid numbers");

        bytes32 goldTicket = _computeGoldTicketHash(numbers[0], numbers[1], numbers[2], etherball);
        bytes32 silverTicket = _computeSilverTicketHash(numbers[0], numbers[1], numbers[2]);
        bytes32 bronzeTicket = _computeBronzeTicketHash(numbers[0], numbers[1]);

        if (!goldTicketOwners[currentGameNumber][goldTicket][msg.sender]) {
            goldTicketOwners[currentGameNumber][goldTicket][msg.sender] = true;
            goldTicketCounts[currentGameNumber][goldTicket] += 1;
        }

        if (!silverTicketOwners[currentGameNumber][silverTicket][msg.sender]) {
            silverTicketOwners[currentGameNumber][silverTicket][msg.sender] = true;
            silverTicketCounts[currentGameNumber][silverTicket] += 1;
        }

        if (!bronzeTicketOwners[currentGameNumber][bronzeTicket][msg.sender]) {
            bronzeTicketOwners[currentGameNumber][bronzeTicket][msg.sender] = true;
            bronzeTicketCounts[currentGameNumber][bronzeTicket] += 1;
        }

        gamePrizePool[currentGameNumber] += ticketPrice;

        emit TicketPurchased(msg.sender, currentGameNumber, numbers, etherball);
    }

    /**
     * @dev Validates the ticket numbers against the current game's difficulty
     * @param numbers Array of 3 main numbers
     * @param etherball The etherball number
     * @param gameNumber The game number to validate against
     * @return bool indicating if the numbers are valid
     */
    function _validateNumbers(uint256[3] memory numbers, uint256 etherball, uint256 gameNumber) internal view returns (bool) {
        Difficulty difficulty = gameDifficulty[gameNumber];
        (uint256 maxNumber, uint256 maxEtherball) = _getDifficultyParams(difficulty);

        for (uint256 i = 0; i < 3; i++) {
            if (numbers[i] < 1 || numbers[i] > maxNumber) {
                return false;
            }
        }

        if (etherball < 1 || etherball > maxEtherball) {
            return false;
        }

        return true;
    }

    /**
     * @dev Computes the hash for a gold ticket
     * @param numberOne First main number
     * @param numberTwo Second main number
     * @param numberThree Third main number
     * @param etherball The etherball number
     * @return bytes32 Hash of the gold ticket
     */
    function _computeGoldTicketHash(uint256 numberOne, uint256 numberTwo, uint256 numberThree, uint256 etherball) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(numberOne, numberTwo, numberThree, etherball));
    }

    /**
     * @dev Computes the hash for a silver ticket
     * @param numberOne First main number
     * @param numberTwo Second main number
     * @param numberThree Third main number
     * @return bytes32 Hash of the silver ticket
     */
    function _computeSilverTicketHash(uint256 numberOne, uint256 numberTwo, uint256 numberThree) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(numberOne, numberTwo, numberThree));
    }

    /**
     * @dev Computes the hash for a bronze ticket
     * @param numberOne First main number
     * @param numberTwo Second main number
     * @return bytes32 Hash of the bronze ticket
     */
    function _computeBronzeTicketHash(uint256 numberOne, uint256 numberTwo) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(numberOne, numberTwo));
    }

    /**
     * @dev Initiates the lottery draw process
     */
    function initiateDraw() external nonReentrant {
        require(!gameDrawInitiated[currentGameNumber], "Draw already initiated for current game");
        require(block.timestamp >= lastDrawTime + DRAW_MIN_TIME_PERIOD, "Time interval not passed");
        require(gamePrizePool[currentGameNumber] >= DRAW_MIN_PRIZE_POOL, "Insufficient prize pool");

        lastDrawTime = block.timestamp;
        gameDrawInitiated[currentGameNumber] = true;

        uint256 targetSetBlock = block.number + DRAW_DELAY_SECURITY_BUFFER;
        require(targetSetBlock > block.number, "Invalid target block");
        gameRandomBlock[currentGameNumber] = targetSetBlock;

        _startNextGame();

        emit DrawInitiated(currentGameNumber - 1, targetSetBlock);
    }

    /**
     * @dev Starts the next game and updates game parameters
     */
    function _startNextGame() internal {
        Difficulty currentDifficulty = gameDifficulty[currentGameNumber];

        ++currentGameNumber;
        gameStartBlock[currentGameNumber] = block.number;

        if (newDifficulty != currentDifficulty && newDifficultyGame == currentGameNumber) {
            gameDifficulty[currentGameNumber] = newDifficulty;
        } else {
            gameDifficulty[currentGameNumber] = gameDifficulty[currentGameNumber - 1];
        }

        if (newTicketPrice != 0 && newTicketPriceGameNumber == currentGameNumber) {
            require(newTicketPrice > 0, "Invalid new ticket price");
            ticketPrice = newTicketPrice;
            newTicketPrice = 0;
        }

        if (newVDFContract != address(0) && newVDFContractGameNumber == currentGameNumber) {
            vdfContract = VDFPietrzak(newVDFContract);
            newVDFContract = address(0);
        }
    }

    /**
     * @dev Sets the random value for a given game
     * @param gameNumber The game number to set the random value for
     */
    function setRandom(uint256 gameNumber) external {
        require(gameDrawInitiated[gameNumber], "Draw not initiated for this game");
        require(block.number >= gameRandomBlock[gameNumber], "Buffer period not yet passed");
        require(gameRandomValue[gameNumber] == 0, "Random has already been set");
        
        uint256 randomValue = prevrandaoValues[currentIndex];
        gameRandomValue[gameNumber] = randomValue;
        emit RandomSet(gameNumber, randomValue);
        currentIndex = (currentIndex + 1) % prevrandaoValues.length;

        // gameRandomValue[gameNumber] = block.prevrandao;
        // emit RandomSet(gameNumber, block.prevrandao);
    }

    /**
     * @dev Submits and verifies the VDF proof for a given game
     * @param gameNumber The game number to submit the proof for
     * @param v Array of BigNumber values for VDF verification
     * @param y The final output of the VDF
     */
    function submitVDFProof(uint256 gameNumber, BigNumber[] memory v, BigNumber memory y) external nonReentrant {
        require(gameRandomValue[gameNumber] != 0, "Random value not set for this game");
        require(!gameVDFValid[gameNumber], "VDF proof already submitted for this game");

        // VDF Verification
        (bytes memory val, uint256 bitlen) = uint256ToBigNumber(gameRandomValue[gameNumber]);
        BigNumber memory x = BigNumber({val: val, bitlen: bitlen});

        bool isValid = vdfContract.verifyPietrzak(v, x, y);
        require(isValid, "Invalid VDF proof");

        gameVDFValid[gameNumber] = true;
        _setWinningNumbers(gameNumber, y.val);
        emit VDFProofSubmitted(msg.sender, gameNumber);
    }

    /**
     * @dev Sets the winning numbers for a given game based on VDF output
     * @param gameNumber The game number to set winning numbers for
     * @param vdfOutput The output of the VDF function
     */
    function _setWinningNumbers(uint256 gameNumber, bytes memory vdfOutput) internal {
        Difficulty difficulty = gameDifficulty[gameNumber];
        (uint256 maxNumber, uint256 maxEtherball) = _getDifficultyParams(difficulty);

        bytes32 randomSeed = keccak256(vdfOutput);
        uint256[4] memory winningNumbers;

        for (uint256 i = 0; i < 4; i++) {
            uint256 maxValue = i < 3 ? maxNumber : maxEtherball;
            winningNumbers[i] = _generateUnbiasedRandomNumber(randomSeed, i, maxValue);
        }

        gameWinningNumbers[gameNumber] = winningNumbers;
        emit WinningNumbersSet(gameNumber, winningNumbers[0], winningNumbers[1], winningNumbers[2], winningNumbers[3]);
    }

    /**
     * @dev Generates an unbiased random number within a given range
     * @param seed The seed for randomness
     * @param nonce A nonce to ensure uniqueness
     * @param maxValue The maximum value (inclusive) of the random number
     * @return A random number between 1 and maxValue
     */
    function _generateUnbiasedRandomNumber(bytes32 seed, uint256 nonce, uint256 maxValue) internal pure returns (uint256) {
        uint256 maxAllowed = type(uint256).max - (type(uint256).max % maxValue);

        while (true) {
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(seed, nonce)));
            if (randomNumber < maxAllowed) {
                return (randomNumber % maxValue) + 1;
            }
            nonce++;
        }

        revert("Failed to generate unbiased random number");
    }

    /**
     * @dev Verifies the VDF proof for a past game
     * @param gameNumber The game number to verify
     * @param v Array of BigNumber values for VDF verification
     * @param y The final output of the VDF
     * @return calculatedNumbers The calculated winning numbers
     * @return isValid Whether the proof is valid
     */
    function verifyPastGameVDF(uint256 gameNumber, BigNumber[] memory v, BigNumber memory y) external view returns (uint256[4] memory calculatedNumbers, bool isValid) {
        require(gameNumber < currentGameNumber, "Game has not ended yet");
        require(gameRandomValue[gameNumber] != 0, "Random value not set for this game");

        (bytes memory val, uint256 bitlen) = uint256ToBigNumber(gameRandomValue[gameNumber]);
        BigNumber memory x = BigNumber({val: val, bitlen: bitlen});
        isValid = vdfContract.verifyPietrzak(v, x, y);

        if (!isValid) {
            return (calculatedNumbers, false);
        }

        Difficulty difficulty = gameDifficulty[gameNumber];
        (uint256 maxNumber, uint256 maxEtherball) = _getDifficultyParams(difficulty);

        bytes32 randomSeed = keccak256(y.val);

        for (uint256 i = 0; i < 4; i++) {
            uint256 maxValue = i < 3 ? maxNumber : maxEtherball;
            calculatedNumbers[i] = _generateUnbiasedRandomNumber(randomSeed, i, maxValue);
        }

        for (uint256 i = 0; i < 4; i++) {
            if (calculatedNumbers[i] != gameWinningNumbers[gameNumber][i]) {
                isValid = false;
                break;
            }
        }

        return (calculatedNumbers, isValid);
    }

    /**
     * @dev Calculates and sets the payouts for a given game
     * @param gameNumber The game number to calculate payouts for
     */
    function calculatePayouts(uint256 gameNumber) external nonReentrant {
        require(gameVDFValid[gameNumber], "VDF proof not yet validated for this game");
        require(gameDrawCompleted[gameNumber] != true, "Payouts already calculated for this game");

        uint256 prizePool = gamePrizePool[gameNumber];
        (uint256 goldPrize, uint256 silverPrize, uint256 bronzePrize, uint256 fee) = _calculatePrizes(prizePool);

        fee = _handleExcessFee(fee);

        (uint256 goldWinnerCount, uint256 silverWinnerCount, uint256 bronzeWinnerCount) = _getWinnerCounts(gameNumber);

        (uint256 goldPrizePerWinner, uint256 silverPrizePerWinner, uint256 bronzePrizePerWinner) = _calculatePrizesPerWinner(goldPrize, silverPrize, bronzePrize, goldWinnerCount, silverWinnerCount, bronzeWinnerCount);

        _storeGameOutcomes(gameNumber, goldPrizePerWinner, silverPrizePerWinner, bronzePrizePerWinner, goldWinnerCount);

        _handleExcessPrizePool(prizePool, goldPrizePerWinner, silverPrizePerWinner, bronzePrizePerWinner, goldWinnerCount, silverWinnerCount, bronzeWinnerCount, fee, gameNumber);

        gameDrawCompleted[gameNumber] = true;
        emit GamePrizePayoutInfo(gameNumber, goldPrizePerWinner, silverPrizePerWinner, bronzePrizePerWinner);

        _sendFee(fee);
    }

    /**
     * @dev Calculates the prizes for gold, silver, bronze, and fee
     * @param prizePool The total prize pool
     * @return goldPrize The gold prize amount
     * @return silverPrize The silver prize amount
     * @return bronzePrize The bronze prize amount
     * @return fee The fee amount
     */
    function _calculatePrizes(uint256 prizePool) internal pure returns (uint256 goldPrize, uint256 silverPrize, uint256 bronzePrize, uint256 fee) {
        goldPrize = (prizePool * GOLD_PERCENTAGE) / BASIS_POINTS;
        silverPrize = (prizePool * SILVER_PLACE_PERCENTAGE) / BASIS_POINTS;
        bronzePrize = (prizePool * BRONZE_PLACE_PERCENTAGE) / BASIS_POINTS;
        fee = (prizePool * FEE_PERCENTAGE) / BASIS_POINTS;
    }

    /**
     * @dev Handles excess fee by transferring it to the current game's prize pool
     * @param fee The calculated fee
     * @return The adjusted fee amount
     */
    function _handleExcessFee(uint256 fee) internal returns (uint256) {
        if (fee > FEE_MAX_IN_ETH) {
            uint256 excessFee = fee - FEE_MAX_IN_ETH;
            fee = FEE_MAX_IN_ETH;
            gamePrizePool[currentGameNumber] += excessFee;
        }
        return fee;
    }

    /**
     * @dev Gets the count of winners for each prize tier
     * @param gameNumber The game number to get winner counts for
     * @return goldWinnerCount The number of gold winners
     * @return silverWinnerCount The number of silver winners
     * @return bronzeWinnerCount The number of bronze winners
     */
    function _getWinnerCounts(uint256 gameNumber) internal view returns (uint256 goldWinnerCount, uint256 silverWinnerCount, uint256 bronzeWinnerCount) {
        uint256[4] memory winningNumbers = gameWinningNumbers[gameNumber];
        bytes32 goldTicketHash = _computeGoldTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2], winningNumbers[3]);
        bytes32 silverTicketHash = _computeSilverTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2]);
        bytes32 bronzeTicketHash = _computeBronzeTicketHash(winningNumbers[0], winningNumbers[1]);

        goldWinnerCount = goldTicketCounts[gameNumber][goldTicketHash];
        silverWinnerCount = silverTicketCounts[gameNumber][silverTicketHash];
        bronzeWinnerCount = bronzeTicketCounts[gameNumber][bronzeTicketHash];
    }

    /**
     * @dev Calculates the prize amount per winner for each tier
     * @param goldPrize Total gold prize
     * @param silverPrize Total silver prize
     * @param bronzePrize Total bronze prize
     * @param goldWinnerCount Number of gold winners
     * @param silverWinnerCount Number of silver winners
     * @param bronzeWinnerCount Number of bronze winners
     * @return goldPrizePerWinner Prize per gold winner
     * @return silverPrizePerWinner Prize per silver winner
     * @return bronzePrizePerWinner Prize per bronze winner
     */
    function _calculatePrizesPerWinner(
        uint256 goldPrize, 
        uint256 silverPrize, 
        uint256 bronzePrize, 
        uint256 goldWinnerCount, 
        uint256 silverWinnerCount, 
        uint256 bronzeWinnerCount
    ) internal pure returns (uint256 goldPrizePerWinner, uint256 silverPrizePerWinner, uint256 bronzePrizePerWinner) {
        goldPrizePerWinner = goldWinnerCount > 0 ? goldPrize / goldWinnerCount : 0;
        silverPrizePerWinner = silverWinnerCount > 0 ? silverPrize / silverWinnerCount : 0;
        bronzePrizePerWinner = bronzeWinnerCount > 0 ? bronzePrize / bronzeWinnerCount : 0;
    }

    /**
     * @dev Stores the game outcomes and updates consecutive game counters
     * @param gameNumber The game number
     * @param goldPrizePerWinner Prize per gold winner
     * @param silverPrizePerWinner Prize per silver winner
     * @param bronzePrizePerWinner Prize per bronze winner
     * @param goldWinnerCount Number of gold winners
     */
    function _storeGameOutcomes(
        uint256 gameNumber, 
        uint256 goldPrizePerWinner, 
        uint256 silverPrizePerWinner, 
        uint256 bronzePrizePerWinner, 
        uint256 goldWinnerCount
    ) internal {
        gamePayouts[gameNumber] = [goldPrizePerWinner, silverPrizePerWinner, bronzePrizePerWinner];
        gameDrawnBlock[gameNumber] = block.number;

        if (goldWinnerCount > 0) {
            consecutiveJackpotGames++;
            consecutiveNonJackpotGames = 0;
        } else {
            consecutiveNonJackpotGames++;
            consecutiveJackpotGames = 0;
        }
    }

    /**
     * @dev Handles excess prize pool by transferring it to the next game
     * @param prizePool Total prize pool
     * @param goldPrizePerWinner Prize per gold winner
     * @param silverPrizePerWinner Prize per silver winner
     * @param bronzePrizePerWinner Prize per bronze winner
     * @param goldWinnerCount Number of gold winners
     * @param silverWinnerCount Number of silver winners
     * @param bronzeWinnerCount Number of bronze winners
     * @param fee The fee amount
     * @param gameNumber The current game number
     * @return excessPrizePool The amount of excess prize pool
     */
    function _handleExcessPrizePool(
        uint256 prizePool,
        uint256 goldPrizePerWinner,
        uint256 silverPrizePerWinner,
        uint256 bronzePrizePerWinner,
        uint256 goldWinnerCount,
        uint256 silverWinnerCount,
        uint256 bronzeWinnerCount,
        uint256 fee,
        uint256 gameNumber
    ) internal returns (uint256 excessPrizePool) {
        uint256 goldPaidOut = goldPrizePerWinner * goldWinnerCount;
        uint256 silverPaidOut = silverPrizePerWinner * silverWinnerCount;
        uint256 bronzePaidOut = bronzePrizePerWinner * bronzeWinnerCount;

        excessPrizePool = prizePool - (goldPaidOut + silverPaidOut + bronzePaidOut + fee);

        if (excessPrizePool > 0) {
            gamePrizePool[currentGameNumber] += excessPrizePool;
            emit ExcessPrizePoolTransferred(gameNumber, currentGameNumber, excessPrizePool);
        }

        return excessPrizePool;
    }

    /**
     * @dev Sends the fee to the fee recipient
     * @param fee The amount of fee to send
     */
    function _sendFee(uint256 fee) internal {
        (bool success, ) = payable(feeRecipient).call{value: fee}("");
        require(success, "Fee transfer failed");
    }

    /**
     * @dev Allows a player to claim their prize
     * @param gameNumber The game number to claim the prize for
     */
    function claimPrize(uint256 gameNumber) external nonReentrant {
        require(gameDrawCompleted[gameNumber], "Game draw not completed yet");
        require(!prizesClaimed[gameNumber][msg.sender], "Prize already claimed");

        uint256 totalPrize = _calculateTotalPrize(gameNumber);
        require(totalPrize > 0, "No prize to claim");

        prizesClaimed[gameNumber][msg.sender] = true;
        _sendPrize(msg.sender, totalPrize);

        emit PrizeClaimed(gameNumber, msg.sender, totalPrize);
    }

    /**
     * @dev Calculates the total prize for a player in a given game
     * @param gameNumber The game number to calculate the prize for
     * @return totalPrize The total prize amount
     */
    function _calculateTotalPrize(uint256 gameNumber) internal view returns (uint256 totalPrize) {
        uint256[3] memory payouts = gamePayouts[gameNumber];
        uint256[4] memory winningNumbers = gameWinningNumbers[gameNumber];

        bytes32 goldTicketHash = _computeGoldTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2], winningNumbers[3]);
        if (goldTicketOwners[gameNumber][goldTicketHash][msg.sender]) {
            totalPrize += payouts[0];
        }

        bytes32 silverTicketHash = _computeSilverTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2]);
        if (silverTicketOwners[gameNumber][silverTicketHash][msg.sender]) {
            totalPrize += payouts[1];
        }

        bytes32 bronzeTicketHash = _computeBronzeTicketHash(winningNumbers[0], winningNumbers[1]);
        if (bronzeTicketOwners[gameNumber][bronzeTicketHash][msg.sender]) {
            totalPrize += payouts[2];
        }

        return totalPrize;
    }

    /**
     * @dev Sends the prize to the winner
     * @param winner The address of the winner
     * @param amount The amount of the prize
     */
    function _sendPrize(address winner, uint256 amount) internal {
        (bool success, ) = payable(winner).call{value: amount}("");
        require(success, "Prize transfer failed");
    }

    /**
     * @dev Allows a gold ticket winner to mint an NFT
     * @param gameNumber The game number to mint the NFT for
     */
    function mintWinningNFT(uint256 gameNumber) external nonReentrant {
        bytes32 goldTicketHash = _computeGoldTicketHash(gameWinningNumbers[gameNumber][0], gameWinningNumbers[gameNumber][1], gameWinningNumbers[gameNumber][2], gameWinningNumbers[gameNumber][3]);

        require(goldTicketOwners[gameNumber][goldTicketHash][msg.sender], "Not a gold ticket winner");
        require(gameDrawCompleted[gameNumber] == true, "Game draw not completed yet");
        require(!hasClaimedNFT[gameNumber][msg.sender], "NFT already claimed for this game");

        uint256[3] memory payouts = gamePayouts[gameNumber];

        uint256 tokenId = uint256(keccak256(abi.encodePacked(gameNumber, msg.sender)));
        nftPrize.mintNFT(msg.sender, tokenId, gameNumber, gameWinningNumbers[gameNumber], payouts[0]);

        hasClaimedNFT[gameNumber][msg.sender] = true;
        emit NFTMinted(msg.sender, tokenId, gameNumber);
    }

    /**
     * @dev Changes the difficulty of the game based on consecutive wins/losses
     */
    function changeDifficulty() external {
        require(currentGameNumber > 3, "Not enough games played");
        require(currentGameNumber >= newDifficultyGame + 3, "Too soon to change difficulty");

        Difficulty currentDifficulty = gameDifficulty[currentGameNumber];
        Difficulty newDifficultyValue = currentDifficulty;

        if (consecutiveJackpotGames >= 3 && currentDifficulty != Difficulty.Hard) {
            newDifficultyValue = Difficulty(uint(currentDifficulty) + 1);
        } else if (consecutiveNonJackpotGames >= 3 && currentDifficulty != Difficulty.Easy) {
            newDifficultyValue = Difficulty(uint(currentDifficulty) - 1);
        }

        if (newDifficultyValue != currentDifficulty) {
            newDifficulty = newDifficultyValue;
            newDifficultyGame = currentGameNumber + 1;
            emit DifficultyChanged(currentGameNumber + 1, newDifficultyValue);

            // Reset counters after difficulty change
            consecutiveJackpotGames = 0;
            consecutiveNonJackpotGames = 0;
        }
    }

    /**
     * @dev Returns the current game information
     * @return gameNumber The current game number
     * @return difficulty The current game difficulty
     * @return prizePool The current prize pool
     * @return drawTime The next possible draw time
     * @return timeUntilDraw The time remaining until the next draw
     */
    function getCurrentGameInfo() external view returns (
        uint256 gameNumber,
        Difficulty difficulty,
        uint256 prizePool,
        uint256 drawTime,
        uint256 timeUntilDraw
    ) {
        gameNumber = currentGameNumber;
        difficulty = gameDifficulty[gameNumber];
        prizePool = gamePrizePool[gameNumber];
        drawTime = lastDrawTime + DRAW_MIN_TIME_PERIOD;
        timeUntilDraw = drawTime > block.timestamp ? drawTime - block.timestamp : 0;
    }

    /**
     * @dev Retrieves basic information for a range of games
     * @param startGameId The ID of the first game in the range
     * @param endGameId The ID of the last game in the range
     * @return gameInfos An array of GameBasicInfo structs containing the requested game information
     */
    function getBasicGameInfo(uint256 startGameId, uint256 endGameId) external view returns (
        GameBasicInfo[] memory gameInfos
    ) {
        require(startGameId <= endGameId, "Invalid game range");
        require(endGameId - startGameId <= 10, "Max 10 games per query");
        require(endGameId <= currentGameNumber, "End game ID exceeds current game");

        uint256 gameCount = endGameId - startGameId + 1;
        gameInfos = new GameBasicInfo[](gameCount);

        for (uint256 i = 0; i < gameCount; i++) {
            uint256 gameId = startGameId + i;
            GameStatus status = gameDrawCompleted[gameId] ? GameStatus.Completed :
                                (gameDrawInitiated[gameId] ? GameStatus.Drawing : GameStatus.InPlay);

            (uint256 goldWinners, uint256 silverWinners, uint256 bronzeWinners) = _getWinnerCounts(gameId);
            uint256 totalWinners = goldWinners + silverWinners + bronzeWinners;

            gameInfos[i] = GameBasicInfo({
                gameId: gameId,
                status: status,
                prizePool: gamePrizePool[gameId],
                numberOfWinners: totalWinners,
                winningNumbers: [gameWinningNumbers[gameId][0], gameWinningNumbers[gameId][1], gameWinningNumbers[gameId][2], gameWinningNumbers[gameId][3]]
            });
        }
    }

    /**
     * @dev Retrieves detailed information for a specific game
     * @param gameId The ID of the game to retrieve information for
     * @return A GameDetailedInfo struct containing detailed information about the specified game
     */
    function getDetailedGameInfo(uint256 gameId) external view returns (GameDetailedInfo memory) {
        require(gameId <= currentGameNumber, "Game ID exceeds current game");

        GameStatus status = gameDrawCompleted[gameId] ? GameStatus.Completed :
                            (gameDrawInitiated[gameId] ? GameStatus.Drawing : GameStatus.InPlay);
        
        (uint256 goldWinners, uint256 silverWinners, uint256 bronzeWinners) = _getWinnerCounts(gameId);
        uint256 totalWinners = goldWinners + silverWinners + bronzeWinners;
        
        return GameDetailedInfo({
            gameId: gameId,
            status: status,
            prizePool: gamePrizePool[gameId],
            numberOfWinners: totalWinners,
            goldWinners: goldWinners,
            silverWinners: silverWinners,
            bronzeWinners: bronzeWinners,
            winningNumbers: [gameWinningNumbers[gameId][0], gameWinningNumbers[gameId][1], gameWinningNumbers[gameId][2], gameWinningNumbers[gameId][3]],
            difficulty: gameDifficulty[gameId],
            drawInitiatedBlock: gameDrawInitiated[gameId] ? gameRandomBlock[gameId] - DRAW_DELAY_SECURITY_BUFFER : 0,
            randaoBlock: gameRandomBlock[gameId],
            randaoValue: gameRandomValue[gameId],
            payouts: [gamePayouts[gameId][0], gamePayouts[gameId][1], gamePayouts[gameId][2]]
        });
    }

    /**
     * @dev Checks if a user has won any prize in a specific game
     * @param gameNumber The game number to check
     * @param user The address of the user to check
     * @return hasWon Boolean indicating if the user has won any prize
     */
    function hasUserWon(uint256 gameNumber, address user) external view returns (bool hasWon) {
        require(gameNumber <= currentGameNumber, "Invalid game number");
        require(gameDrawCompleted[gameNumber], "Game draw not completed yet");

        uint256[4] memory winningNumbers = gameWinningNumbers[gameNumber];
        
        bytes32 goldTicketHash = _computeGoldTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2], winningNumbers[3]);
        bytes32 silverTicketHash = _computeSilverTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2]);
        bytes32 bronzeTicketHash = _computeBronzeTicketHash(winningNumbers[0], winningNumbers[1]);

        hasWon = goldTicketOwners[gameNumber][goldTicketHash][user] ||
                 silverTicketOwners[gameNumber][silverTicketHash][user] ||
                 bronzeTicketOwners[gameNumber][bronzeTicketHash][user];
    }

    /**
     * @dev Gets detailed information about a user's winnings for a specific game
     * @param gameNumber The game number to check
     * @param user The address of the user to check
     * @return goldWin Boolean indicating if the user won the gold prize
     * @return silverWin Boolean indicating if the user won the silver prize
     * @return bronzeWin Boolean indicating if the user won the bronze prize
     * @return totalPrize The total prize amount won by the user
     * @return claimed Boolean indicating if the user has claimed their prize
     */
    function getUserGameWinnings(uint256 gameNumber, address user) external view returns (
        bool goldWin,
        bool silverWin,
        bool bronzeWin,
        uint256 totalPrize,
        bool claimed
    ) {
        require(gameNumber <= currentGameNumber, "Invalid game number");
        require(gameDrawCompleted[gameNumber], "Game draw not completed yet");

        uint256[4] memory winningNumbers = gameWinningNumbers[gameNumber];
        uint256[3] memory payouts = gamePayouts[gameNumber];
        
        bytes32 goldTicketHash = _computeGoldTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2], winningNumbers[3]);
        bytes32 silverTicketHash = _computeSilverTicketHash(winningNumbers[0], winningNumbers[1], winningNumbers[2]);
        bytes32 bronzeTicketHash = _computeBronzeTicketHash(winningNumbers[0], winningNumbers[1]);

        goldWin = goldTicketOwners[gameNumber][goldTicketHash][user];
        silverWin = silverTicketOwners[gameNumber][silverTicketHash][user];
        bronzeWin = bronzeTicketOwners[gameNumber][bronzeTicketHash][user];

        if (goldWin) totalPrize += payouts[0];
        if (silverWin) totalPrize += payouts[1];
        if (bronzeWin) totalPrize += payouts[2];

        claimed = prizesClaimed[gameNumber][user];
    }

    /**
     * @dev Returns the parameters for a given difficulty level
     * @param difficulty The difficulty level
     * @return maxNumber The maximum number for main numbers
     * @return maxEtherball The maximum number for the etherball
     */
    function _getDifficultyParams(Difficulty difficulty) internal pure returns (uint256 maxNumber, uint256 maxEtherball) {
        if (difficulty == Difficulty.Easy) {
            return (EASY_MAX, EASY_ETHERBALL_MAX);
        } else if (difficulty == Difficulty.Medium) {
            return (MEDIUM_MAX, MEDIUM_ETHERBALL_MAX);
        } else {
            return (HARD_MAX, HARD_ETHERBALL_MAX);
        }
    }

    /**
     * @dev Sets a new ticket price (owner only)
     * @param _newPrice The new ticket price
     */
    function setTicketPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price must be positive");
        require(_newPrice != ticketPrice, "New price must be different");
        newTicketPrice = _newPrice;
        newTicketPriceGameNumber = currentGameNumber + 10;
        emit TicketPriceChangeScheduled(_newPrice, newTicketPriceGameNumber);
    }

    /**
     * @dev Sets a new VDF contract address (owner only)
     * @param _newVDFContract The address of the new VDF contract
     */
    function setNewVDFContract(address _newVDFContract) external onlyOwner {
        require(_newVDFContract != address(0) && _newVDFContract != address(vdfContract), "Invalid VDF contract address");
        newVDFContract = _newVDFContract;
        newVDFContractGameNumber = currentGameNumber + 10;
    }

    /**
     * @dev Sets a new fee recipient address (owner only)
     * @param _newFeeRecipient The address of the new fee recipient
     */
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        require(_newFeeRecipient != address(0) && _newFeeRecipient != feeRecipient, "Invalid fee recipient address");
        feeRecipient = _newFeeRecipient;
        emit FeeRecipientChanged(_newFeeRecipient);
    }

    /**
    * @dev Converts a uint256 to a BigNumber input format used in VDF function.
    * 
    * @param input The uint256 value to be converted
    * @return val The byte array representation of the input
    * @return bitlen The bit length of the significant part of the input
    */
    function uint256ToBigNumber(uint256 input) public pure returns (bytes memory val, uint256 bitlen) {
        // Convert the input to a byte array
        val = abi.encodePacked(input);
        
        // Initialize bitlen to the maximum possible for uint256
        bitlen = 256;

        // Count leading zero bytes to determine the actual bit length
        uint256 i = 0;
        while (i < 32 && val[i] == 0) {
            bitlen -= 8;  // Decrease bitlen by 8 for each leading zero byte
            i++;
        }

        // Ensure bitlen is at least 1, even for input 0
        if (bitlen == 0) {
            bitlen = 1;
        }
    }

    function resetIndex() external {
        currentIndex = 0;
    }

    /**
     * @dev Fallback function to receive ETH and add it to the prize pool
     */
    receive() external payable {
        gamePrizePool[currentGameNumber] += msg.value;
    }
}