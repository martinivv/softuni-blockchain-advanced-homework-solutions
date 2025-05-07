// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

error RandomizedNFT__AlreadyRequested();
error RandomizedNFT__TransferFailed();
error RandomizedNFT__NeedMoreETHSent();
error RandomizedNFT__NotOwner();
error RandomizedNFT__ZeroAddress();

contract RandomizedNFT is ERC721URIStorage, VRFConsumerBaseV2Plus {
    struct MintRequest {
        address requester;
        bool fulfilled;
    }

    /* ============================================================================================== */
    /*                                         STATE VARIABLES                                        */
    /* ============================================================================================== */

    // Chainlink VRF Variables
    uint16 private constant REQ_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 4;

    uint256 private immutable SUBSCRIPTION_ID;
    bytes32 private immutable GAS_LANE;
    uint32 private immutable CALLBACK_GAS_LIMIT;

    // NFT Variables
    uint256 private tokenCounter;
    uint256 private mintFee;

    mapping(uint256 => MintRequest) private mintRequests;

    /* ============================================================================================== */
    /*                                             EVENTS                                             */
    /* ============================================================================================== */

    event MintRequested(uint256 indexed requestId, address requester);
    event NFTMinted(uint256 indexed tokenId, address nftOwner);

    /* ============================================================================================== */
    /*                                            FUNCTIONS                                           */
    /* ============================================================================================== */

    constructor(
        uint256 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        address vrfCoordinatorAddress,
        uint256 _mintFee
    ) VRFConsumerBaseV2Plus(vrfCoordinatorAddress) ERC721("RandomizedMythicalCreatures", "RMC") {
        SUBSCRIPTION_ID = subscriptionId;
        GAS_LANE = gasLane;
        CALLBACK_GAS_LIMIT = callbackGasLimit;

        mintFee = _mintFee;
        tokenCounter = 0;
    }

    function requestMint() external payable {
        if (msg.value < mintFee) {
            revert RandomizedNFT__NeedMoreETHSent();
        }

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: GAS_LANE,
                subId: SUBSCRIPTION_ID,
                requestConfirmations: REQ_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            })
        );

        mintRequests[requestId] = MintRequest({requester: msg.sender, fulfilled: false});

        emit MintRequested(requestId, msg.sender);
    }

    /**
     * @dev Callback function used by Chainlink VRF
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address nftOwner = mintRequests[requestId].requester;

        if (mintRequests[requestId].fulfilled) {
            revert RandomizedNFT__AlreadyRequested();
        }

        mintRequests[requestId].fulfilled = true;

        generateAttributes(randomWords);

        uint256 newTokenId = tokenCounter;
        tokenCounter++;
        _safeMint(nftOwner, newTokenId);
        emit NFTMinted(newTokenId, nftOwner);
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = payable(owner()).call{value: amount}("");
        if (!success) {
            revert RandomizedNFT__TransferFailed();
        }
    }

    /* ============================================================================================== */
    /*                                         VIEW FUNCTIONS                                         */
    /* ============================================================================================== */

    function getMintFee() external view returns (uint256) {
        return mintFee;
    }

    function getTokenCounter() external view returns (uint256) {
        return tokenCounter;
    }

    /* ============================================================================================== */
    /*                                       INTERNAL FUNCTIONS                                       */
    /* ============================================================================================== */

    function generateAttributes(uint256[] calldata randomWords) internal view {
        // Generate attributes and attach them to the NFT
    }
}
