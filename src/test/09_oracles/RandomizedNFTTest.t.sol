// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {RandomizedNFT, RandomizedNFT__NeedMoreETHSent} from "../../09_oracles/RandomizedNFT.sol";
import {LinkToken} from "./mocks/LinkToken.sol";

contract RandomizedNFTTest is Test {
    /* ============================================================================================== */
    /*                                         STATE VARIABLES                                        */
    /* ============================================================================================== */
    RandomizedNFT public randomizedNFT;
    VRFCoordinatorV2_5Mock public vrfCoordinator;
    LinkToken public linkToken;

    // Constants
    uint64 private constant SUBSCRIPTION_ID = 1;
    bytes32 private constant GAS_LANE = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 private constant CALLBACK_GAS_LIMIT = 2500000;
    uint256 private constant MINT_FEE = 0.01 ether;

    // Testing accounts
    address public MINTER = makeAddr("minter");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;
    uint256 public constant NATIVE_BALANCE = 10 ether;

    /* ============================================================================================== */
    /*                                             EVENTS                                             */
    /* ============================================================================================== */
    event MintRequested(uint256 indexed requestId, address requester);
    event NFTMinted(uint256 indexed tokenId, address nftOwner);
    event OwnershipTransferred(address indexed previous, address indexed newAddress);

    // Allow the contract to receive ETH
    receive() external payable {}

    function setUp() external {
        // 1. Deploy VRF and Link Token mocks
        vrfCoordinator = new VRFCoordinatorV2_5Mock(0.25 ether, 3000000000, 0.001 ether);
        linkToken = new LinkToken();

        // 2. Create the subscription and fund it with both LINK and Native tokens
        uint256 subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, LINK_BALANCE);

        // 3. Fund with native tokens
        vm.deal(address(this), NATIVE_BALANCE);
        vrfCoordinator.fundSubscriptionWithNative{value: NATIVE_BALANCE}(subId);

        // 4. Deploy the RandomizedNFT contract
        randomizedNFT = new RandomizedNFT(subId, GAS_LANE, CALLBACK_GAS_LIMIT, address(vrfCoordinator), MINT_FEE);

        // 5. Add the consumer
        vrfCoordinator.addConsumer(subId, address(randomizedNFT));

        // 6. Fund the minter
        vm.deal(MINTER, STARTING_USER_BALANCE);
    }

    /* ============================================================================================== */
    /*                                           BASIC TESTS                                          */
    /* ============================================================================================== */

    function testInit() public view {
        assertEq(randomizedNFT.getMintFee(), MINT_FEE);
        assertEq(randomizedNFT.getTokenCounter(), 0);
        assertEq(randomizedNFT.owner(), address(this));
    }

    function testMintFeeUpdate() public {
        uint256 newMintFee = 0.02 ether;
        randomizedNFT.setMintFee(newMintFee);
        assertEq(randomizedNFT.getMintFee(), newMintFee);
    }

    function testMintFeeUpdateFailsForNonOwner() public {
        vm.prank(MINTER);
        vm.expectRevert();
        randomizedNFT.setMintFee(0.02 ether);
    }

    function testWithdrawFails() public {
        vm.prank(MINTER);
        vm.expectRevert();
        randomizedNFT.withdraw();
    }

    /* ============================================================================================== */
    /*                                         MINTING TESTS                                          */
    /* ============================================================================================== */

    function testRequestMintFailsWithInsufficientFunds() public {
        vm.prank(MINTER);
        vm.expectRevert(RandomizedNFT__NeedMoreETHSent.selector);
        randomizedNFT.requestMint{value: MINT_FEE - 0.001 ether}();
    }

    function testRequestMintSuccess() public {
        vm.prank(MINTER);
        vm.expectEmit(true, true, false, true, address(randomizedNFT));
        emit MintRequested(1, MINTER);
        randomizedNFT.requestMint{value: MINT_FEE}();
    }

    function testFulfillRandomWordsAndMintNFT() public {
        vm.prank(MINTER);
        randomizedNFT.requestMint{value: MINT_FEE}();

        uint256[] memory randomWords = new uint256[](4);
        randomWords[0] = 1;
        randomWords[1] = 2;
        randomWords[2] = 50;
        randomWords[3] = 75;

        vm.expectEmit(true, true, false, true, address(randomizedNFT));
        emit NFTMinted(0, MINTER);

        vrfCoordinator.fulfillRandomWordsWithOverride(1, address(randomizedNFT), randomWords);

        assertEq(randomizedNFT.getTokenCounter(), 1);
        assertEq(randomizedNFT.ownerOf(0), MINTER);
    }

    function testMultipleMints() public {
        uint256 mintCount = 3;

        for (uint256 i = 0; i < mintCount; i++) {
            vm.prank(MINTER);
            randomizedNFT.requestMint{value: MINT_FEE}();

            uint256[] memory randomWords = new uint256[](4);
            randomWords[0] = i + 100;
            randomWords[1] = i + 200;
            randomWords[2] = i + 300;
            randomWords[3] = i + 400;

            vrfCoordinator.fulfillRandomWordsWithOverride(i + 1, address(randomizedNFT), randomWords);
        }

        assertEq(randomizedNFT.getTokenCounter(), mintCount);
        assertEq(randomizedNFT.balanceOf(MINTER), mintCount);
    }

    /* ============================================================================================== */
    /*                                        WITHDRAWAL TESTS                                        */
    /* ============================================================================================== */

    function testWithdrawSuccess() public {
        uint256 mintCount = 3;
        uint256 expectedBalance = mintCount * MINT_FEE;

        for (uint256 i = 0; i < mintCount; i++) {
            vm.prank(MINTER);
            randomizedNFT.requestMint{value: MINT_FEE}();
        }

        uint256 preWithdrawBalance = address(this).balance;
        randomizedNFT.withdraw();
        uint256 postWithdrawBalance = address(this).balance;

        assertEq(postWithdrawBalance - preWithdrawBalance, expectedBalance);
        assertEq(address(randomizedNFT).balance, 0);
    }
}
