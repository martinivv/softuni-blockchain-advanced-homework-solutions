// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error EmptyMerkleRoot();

/**
 * @notice Verifies participation in a charity tournament using Merkle trees
 */
contract CharityTournament is Ownable2Step {
    string public constant TOURNAMENT_NAME = "Charity Tournament";
    uint256 public constant TOURNAMENT_TIMESTAMP = 1717776000;

    bytes32 public merkleRoot;

    event MerkleRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot);

    constructor(bytes32 _merkleRoot) Ownable(msg.sender) {
        if (_merkleRoot == bytes32(0)) revert EmptyMerkleRoot();

        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Checks if a specific address is a participant in the tournament
     * @param _participant Address of the participant to check
     * @param _merkleProof The Merkle proof needed for verification
     * @return `true` if the address is a participant, otherwise `false`
     */
    function isParticipant(address _participant, bytes32[] calldata _merkleProof) external view returns (bool) {
        if (_participant == address(0)) {
            return false;
        }

        bytes32 leaf = keccak256(abi.encodePacked(_participant));
        return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Updates the Merkle root
     * @param _newMerkleRoot The new Merkle root to set
     */
    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        if (_newMerkleRoot == bytes32(0)) revert EmptyMerkleRoot();

        bytes32 oldRoot = merkleRoot;
        merkleRoot = _newMerkleRoot;
        emit MerkleRootUpdated(oldRoot, _newMerkleRoot);
    }
}
