// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

event Transfer(address from, address to, uint256 amount);

error AlreadyRegistered();
error NotRegistered();
error AlreadyExists();
error InsufficientBalance();

/**
 * @notice In our unoptimized contracts we have been required to use two data structures:
 * an array and a mapping. We should make gas-optimizations.
 *
 *
 * PREQUISITES:
 * `usersData[user]` is a packed data structure where:
 *   - The least significant bit represents the registration status (1 if registered, 0 if not)
 *   - The remaining bits represent the balance
 *
 * This allows us to store both registration status and balance in a single storage slot,
 * reducing the storage footprint compared to using two separate mappings.
 *
 *
 * ==========================
 * THIS CONTRACT IS USED FOR EDUCATIONAL PURPOSES ONLY.
 * DO NOT USE IT IN PRODUCTION ENVIRONMENTS.
 */
contract OptimizedFunctionGuzzler {
    // Explicit mapping usage
    mapping(address user => uint256) private usersData;

    // Explicit array usage
    mapping(uint256 => bool) private values;
    uint256 private valuesCount;
    uint256 private sum;

    /* ============================================================================================== */
    /*                                      EXPICIT MAPPING USAGE                                     */
    /* ============================================================================================== */

    function registerUser() external {
        if (_isRegistered(msg.sender)) revert AlreadyRegistered();

        // Set the Least Significant Bit (LSB) to 1 to indicate registration
        usersData[msg.sender] |= 1;
    }

    function deposit(uint256 _amount) external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();

        // Shift amount left by 1 and add to userData while preserving isRegistered bit
        usersData[msg.sender] += _amount << 1;
    }

    function transfer(address _to, uint256 _amount) external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();
        if (!_isRegistered(_to)) revert NotRegistered();

        uint256 senderBalance = balances(msg.sender);
        if (senderBalance < _amount) revert InsufficientBalance();

        usersData[msg.sender] -= _amount << 1;

        usersData[_to] += _amount << 1;
        emit Transfer(msg.sender, _to, _amount);
    }

    function balances(address _user) public view returns (uint256) {
        return usersData[_user] >> 1;
    }

    function findUser(address _user) public view returns (bool) {
        return _isRegistered(_user);
    }

    function _isRegistered(address _user) private view returns (bool) {
        return (usersData[_user] & 1) == 1;
    }

    /* ============================================================================================== */
    /*                                      EXPLICIT ARRAY USAGE                                      */
    /* ============================================================================================== */

    function addValue(uint256 _newValue) external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();

        if (values[_newValue]) revert AlreadyExists();

        values[_newValue] = true;
        valuesCount++;
        sum += _newValue;
    }

    function sumValues() external view returns (uint256) {
        return sum;
    }

    function getAverageValue() external view returns (uint256) {
        return valuesCount == 0 ? 0 : sum / valuesCount;
    }
}
