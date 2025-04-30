// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

struct Proposal {
    uint256 id;
    address proposer;
    string description;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
}

contract VotingLogicV1 is Initializable, OwnableUpgradeable {
    mapping(uint256 => Proposal) public proposals;

    uint256 public proposalCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @custom:oz-upgrades-validate-as-initializer
    function initialize() public reinitializer(1) {
        __Ownable_init(msg.sender);
    }

    function createProposal(string memory description) external returns (uint256) {
        proposalCount++;

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: description,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });

        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) revert();

        if (support) {
            proposal.forVotes++;
        } else {
            proposal.againstVotes++;
        }
    }

    function execute(uint256 proposalId) external view virtual returns (bool) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) return false;
        if (proposal.forVotes <= proposal.againstVotes) return false;

        return true;
    }
}
