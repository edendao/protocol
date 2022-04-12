// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferFromToken} from "@protocol/interfaces/TransferFromToken.sol";

import {Comptroller} from "@protocol/Comptroller.sol";

contract Comptrolled {
  Comptroller public comptroller;

  constructor(address _comptroller) {
    comptroller = Comptroller(_comptroller);
  }

  modifier requiresAuth() {
    require(isAuthorized(msg.sender, msg.sig), "Comptrolled: UNAUTHORIZED");
    _;
  }

  function isAuthorized(address user, bytes4 functionSig)
    internal
    view
    returns (bool)
  {
    return (comptroller.canCall(user, address(this), functionSig) ||
      user == comptroller.owner());
  }

  function comptrollerAddress() public view returns (address) {
    return address(comptroller);
  }

  function withdrawTo(address to, uint256 amount) public requiresAuth {
    payable(to).transfer(amount);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 idOrAmount
  ) public requiresAuth {
    TransferFromToken(token).transferFrom(address(this), to, idOrAmount);
  }
}