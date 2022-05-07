// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {ChainEnvironmentTest} from "@test/ChainEnvironmentTest.t.sol";

contract SpaceTest is ChainEnvironmentTest {
  uint256 internal immutable spaceId = omnicast.idOf("prosperity");

  function testMintNameGas() public {
    space.mint{value: 1 ether}("prosperity");
  }

  function testMintName(address caller, uint256 value) public {
    hevm.assume(
      caller != address(this) &&
        caller != address(0) &&
        value >= (space.countRegisteredBy(caller) + 1) * 0.05 ether
    );
    hevm.deal(caller, value);

    hevm.prank(caller);
    uint256 omnicastId = space.mint{value: value}("prosperity");

    assertEq(omnicastId, spaceId);
  }

  function testNoteMintGas() public {
    space.mintTo(address(this), spaceId);
  }

  function testNoteMint(address to) public {
    hevm.assume(to != address(0));

    space.mintTo(to, spaceId);

    assertEq(space.ownerOf(spaceId), to);
  }

  function testMintRequiresAuth(address caller) public {
    hevm.assume(caller != address(0) && caller != address(this));

    hevm.expectRevert("Comptrolled: UNAUTHORIZED");
    hevm.prank(caller);
    space.mintTo(caller, spaceId);
  }
}
