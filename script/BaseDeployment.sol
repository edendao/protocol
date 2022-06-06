// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/interfaces/ILayerZeroEndpoint.sol";

import {Factory} from "@omniprotocol/Factory.sol";
import {Omnibridge} from "@omniprotocol/Omnibridge.sol";
import {Omnicast} from "@omniprotocol/Omnicast.sol";
import {Omnitoken} from "@omniprotocol/Omnitoken.sol";
import {Passport} from "@omniprotocol/Passport.sol";
import {Space} from "@omniprotocol/Space.sol";
import {Steward} from "@omniprotocol/Steward.sol";

contract BaseDeployment is Script {
  function run() public {
    address owner = vm.envAddress("ETH_FROM");
    bool isPrimary = vm.envBool("PRIMARY");

    _deploy(
      isPrimary,
      vm.envAddress("BENEFICIARY"),
      owner,
      vm.envAddress("LZ_ENDPOINT")
    );
  }

  Steward public steward; // Owner & Authority
  Omnitoken internal token; // New, mintable ERC20s
  Omnibridge internal bridge; // Bridge existing ERC20s
  Factory public factory; // Launch new stewards, tokens, and bridges

  Omnicast public omnicast; // Cross-chain Messaging Bridge
  Space public space; // Vanity Namespaces
  Passport public passport; // Identity NFTs

  function _deploy(
    bool isPrimary,
    address beneficiary,
    address owner,
    address lzEndpoint
  ) internal {
    vm.startBroadcast(owner);

    steward = new Steward(beneficiary, owner);

    token = new Omnitoken();
    bridge = new Omnibridge();
    factory = new Factory(
      beneficiary,
      address(steward),
      address(token),
      address(bridge),
      address(lzEndpoint)
    );

    omnicast = new Omnicast(address(steward), address(lzEndpoint));

    space = new Space(address(steward), address(omnicast), isPrimary);
    if (isPrimary) {
      space.mint(owner, "layer1");
      space.mint(owner, "layer2");
      space.mint(owner, "layer3");
      space.mint(owner, "layer4");
      space.mint(owner, "layer5");
      space.mint(owner, "tokenuri");
      space.mint(owner, "profile");
      space.mint(owner, "account");
      space.mint(owner, "refi");
    }

    passport = new Passport(address(steward), address(omnicast));

    omnicast.initialize(
      beneficiary,
      abi.encode(address(space), address(passport))
    );

    vm.stopBroadcast();
  }
}