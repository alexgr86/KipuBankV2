// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import {IOracle} from "./IOracle.sol";

//mock del oraculo
contract Oracle is IOracle {
    function latestAnswer() external pure returns(int256) {
        return 120088170000;
    }
}