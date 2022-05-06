// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {TransferToken} from "@protocol/interfaces/TransferrableToken.sol";
import {Cloneable} from "@protocol/mixins/Cloneable.sol";
import {Comptroller} from "@protocol/Comptroller.sol";

abstract contract Comptrolled is Cloneable {
  Comptroller public comptroller;

  function __initComptrolled(address _comptroller) internal {
    comptroller = Comptroller(payable(_comptroller));
  }

  modifier requiresAuth() {
    require(isAuthorized(msg.sender, msg.sig), "Comptrolled: UNAUTHORIZED");
    _;
  }

  // Delegate to Comptroller
  function isAuthorized(address user, bytes4 functionSig)
    public
    view
    returns (bool)
  {
    return (comptroller.canCall(user, address(this), functionSig) ||
      user == comptroller.owner());
  }

  function comptrollerAddress() public view returns (address) {
    return address(comptroller);
  }

  function withdraw(uint256 amount) external requiresAuth {
    payable(comptrollerAddress()).transfer(amount);
  }

  function withdrawToken(address token, uint256 amount)
    external
    virtual
    requiresAuth
  {
    TransferToken(token).transfer(comptrollerAddress(), amount);
  }
}
