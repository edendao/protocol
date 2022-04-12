// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {BaseProtocolDeployerTest} from "@protocol/test/chainops/0_BaseProtocolDeployer.t.sol";

contract OmnicastTest is BaseProtocolDeployerTest {
  function testMintGas() public {
    omnicast.mint{value: 0.025 ether}();
  }

  function testMint(address to, uint256 value) public {
    hevm.assume(to != address(0) && value > 0.025 ether);
    hevm.deal(to, value);
    hevm.startPrank(to);

    omnicast.mint{value: value}();

    hevm.stopPrank();

    assertEq(omnicast.balanceOf(to), 1);
    assertEq(omnicast.ownerOf(omnicast.idOf(to)), to);
  }

  function testInsufficientValue() public {
    hevm.expectRevert("Omnicast: INSUFFICIENT_VALUE");
    omnicast.mint();
  }

  function testNotAvailable() public {
    omnicast.mint{value: 0.025 ether}();
    hevm.expectRevert("Omnicast: NOT_AVAILABLE");
    omnicast.mint{value: 0.025 ether}();
  }

  function testSendAndReadMessage(address to, bytes memory payload) public {
    omnicast.sendMessage(uint16(block.chainid), to, payload, address(0), "");
    assertEq0(omnicast.readMessageFor(to, myAddress), payload);
  }

  function testUnauthorizedSending(
    address omnicastAddress,
    address omnicastChannel,
    bytes memory payload
  ) public {
    hevm.assume(
      omnicastAddress != address(0) &&
        omnicastChannel != address(0) &&
        omnicastChannel != myAddress
    );

    uint256 omnicastId = omnicast.idOf(omnicastAddress);
    uint256 channelId = omnicast.idOf(omnicastChannel);
    hevm.expectRevert("Omnicast: UNAUTHORIZED_CHANNEL");
    omnicast.sendMessage(
      uint16(block.chainid),
      omnicastId,
      channelId,
      payload,
      address(0),
      ""
    );

    assertEq0(omnicast.readMessageFor(omnicastAddress, omnicastChannel), "");
  }
}
