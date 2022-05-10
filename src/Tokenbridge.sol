// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {SafeTransferLib} from "@protocol/libraries/SafeTransferLib.sol";
import {IOmnitoken} from "@protocol/interfaces/IOmnitoken.sol";

import {Cloneable} from "@protocol/mixins/Cloneable.sol";
import {Comptrolled} from "@protocol/mixins/Comptrolled.sol";
import {ERC20} from "@protocol/mixins/ERC20.sol";
import {Omnichain} from "@protocol/mixins/Omnichain.sol";
import {PublicGood} from "@protocol/mixins/PublicGood.sol";

contract Tokenbridge is
  PublicGood,
  Comptrolled,
  IOmnitoken,
  Omnichain,
  Cloneable
{
  using SafeTransferLib for ERC20;
  ERC20 public asset;

  constructor(address _beneficiary, address _lzEndpoint) {
    __initPublicGood(_beneficiary);
    __initOmnichain(_lzEndpoint);
  }

  // ================================
  // ========== Cloneable ===========
  // ================================
  function initialize(address _beneficiary, bytes calldata _params)
    external
    override
    initializer
  {
    __initPublicGood(_beneficiary);

    (address _lzEndpoint, address _comptroller, address _asset) = abi.decode(
      _params,
      (address, address, address)
    );

    __initOmnichain(_lzEndpoint);
    __initComptrolled(_comptroller);

    asset = ERC20(_asset);
  }

  function clone(address _comptroller, address _asset)
    external
    payable
    returns (address cloneAddress)
  {
    cloneAddress = clone();
    Cloneable(cloneAddress).initialize(
      beneficiary,
      abi.encode(address(lzEndpoint), _comptroller, _asset)
    );
  }

  // ===============================
  // ========= IOmnitoken ==========
  // ===============================
  function circulatingSupply() public view virtual override returns (uint256) {
    unchecked {
      return asset.totalSupply() - asset.balanceOf(address(this));
    }
  }

  function estimateSendFee(
    uint16 toChainId,
    bytes calldata toAddress,
    uint256 amount,
    bool useZRO,
    bytes calldata adapterParams
  ) external view override returns (uint256 nativeFee, uint256 lzFee) {
    (nativeFee, lzFee) = lzEndpoint.estimateFees(
      toChainId,
      address(this),
      abi.encode(toAddress, amount),
      useZRO,
      adapterParams
    );
  }

  function sendFrom(
    address fromAddress,
    uint16 toChainId,
    bytes memory toAddress,
    uint256 amount,
    // solhint-disable-next-line no-unused-vars
    address payable,
    address lzPaymentAddress,
    bytes calldata lzAdapterParams
  ) external payable override {
    asset.safeTransferFrom(fromAddress, address(this), amount);

    lzSend(
      toChainId,
      abi.encode(toAddress, amount),
      lzPaymentAddress,
      lzAdapterParams
    );

    emit SendToChain(
      fromAddress,
      toChainId,
      toAddress,
      amount,
      lzEndpoint.getOutboundNonce(toChainId, address(this))
    );
  }

  function receiveMessage(
    uint16 fromChainId,
    bytes calldata fromContractAddress,
    uint64 nonce,
    bytes calldata payload
  ) internal virtual override {
    (bytes memory toAddressB, uint256 amount) = abi.decode(
      payload,
      (bytes, uint256)
    );
    address toAddress = _addressFromPackedBytes(toAddressB);

    asset.safeTransfer(toAddress, amount);

    emit ReceiveFromChain(
      fromChainId,
      fromContractAddress,
      toAddress,
      amount,
      nonce
    );
  }

  // ==============================
  // ======= Comptrollable ========
  // ==============================
  function withdrawToken(address token, uint256 amount) public override {
    require(address(token) != address(asset), "Tokenbridge: INVALID_TOKEN");
    super.withdrawToken(token, amount);
  }
}
