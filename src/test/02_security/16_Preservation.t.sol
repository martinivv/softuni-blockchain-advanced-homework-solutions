// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.23;

import {Tests} from "@/02_security/core/Tests.sol";
import {PreservationFactory, Preservation} from "@/02_security/levels/16_Preservation/PreservationFactory.sol";
import {HackPreservation} from "@/02_security/levels/16_Preservation/HackPreservation.sol";

contract TestPreservation is Tests {
    Preservation private level;

    /* =============================== SETUP&ATTACK =============================== */

    constructor() {
        levelFactory = new PreservationFactory();
    }

    function setupLevel() internal override {
        levelAddress = payable(this.createLevelInstance());
        level = Preservation(levelAddress);
    }

    function attack() internal override {
        vm.startPrank(PLAYER);

        HackPreservation hack = new HackPreservation();
        hack.attack(level);
        assertEq(level.owner(), PLAYER);

        vm.stopPrank();
    }

    /* =============================== TEST LEVEL =============================== */

    function testLevel() external {
        runLevel();
    }
}
