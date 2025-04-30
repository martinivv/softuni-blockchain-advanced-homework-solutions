// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Proposal} from "./VotingLogicV1.sol";

/// @custom:oz-upgrades-from VotingLogicV1
contract VotingLogicV2 is Initializable, OwnableUpgradeable {
    mapping(uint256 => Proposal) public proposals;

    uint256 public proposalCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @custom:oz-upgrades-validate-as-initializer
    function initialize() public reinitializer(2) {
        __Ownable_init(msg.sender);
    }

    function execute(uint256 proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) return false;

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        if (totalVotes < quorum()) return false;
        if (proposal.forVotes <= proposal.againstVotes) return false;

        return true;
    }

    function quorum() public pure returns (uint256) {
        return 1000;
    }
}
