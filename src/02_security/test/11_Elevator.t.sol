// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.23;

import {Tests} from "@/02_security/core/Tests.sol";
import {ElevatorFactory, Elevator} from "../levels/11_Elevator/ElevatorFactory.sol";
import {HackElevator} from "../levels/11_Elevator/HackElevator.sol";

contract TestElevator is Tests {
    Elevator private level;

    /* =============================== SETUP&ATTACK =============================== */

    constructor() {
        levelFactory = new ElevatorFactory();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance());
        level = Elevator(levelAddress);
    }

    function attack() internal override {
        vm.startPrank(PLAYER);

        HackElevator hack = new HackElevator(levelAddress);
        hack.attack();
        assertTrue(level.top());

        vm.stopPrank();
    }

    /* =============================== TEST LEVEL =============================== */

    function testLevel() external {
        runLevel();
    }
}
