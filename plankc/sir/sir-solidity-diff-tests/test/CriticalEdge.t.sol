// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseTest} from "./BaseTest.sol";

contract CriticalEdgeRef {
    fallback() external payable {
        assembly ("memory-safe") {
            if iszero(calldatasize()) { revert(0, 0) }
            if iszero(callvalue()) { revert(0, 0) }
            sstore(0, callvalue())
            stop()
        }
    }
}

contract CriticalEdgeTest is BaseTest {
    CriticalEdgeRef solRef = new CriticalEdgeRef();
    address sirImpl = makeAddr("sir-critical-edge");

    function setUp() public {
        vm.etch(sirImpl, sir(abi.encode("src/critical_edge.sir", "--init-only")));
    }

    function test_criticalEdge() public {
        uint256 value = 1;
        vm.deal(address(this), value * 2);

        (bool refSucc, bytes memory refOut) = address(solRef).call{value: value}(hex"00");
        (bool sirSucc, bytes memory sirOut) = sirImpl.call{value: value}(hex"00");

        assertEq(refSucc, sirSucc, "different success");
        assertEq(refOut, sirOut, "different output data");
        assertEq(vm.load(address(solRef), bytes32(0)), vm.load(sirImpl, bytes32(0)), "different storage");
    }
}
