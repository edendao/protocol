// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

import { ERC721 } from "@rari-capital/solmate/tokens/ERC721.sol";

import { Authenticated } from "@protocol/mixins/Authenticated.sol";
import { Omnichain } from "@protocol/mixins/Omnichain.sol";

contract Domain is ERC721, Omnichain, Authenticated {
  uint8 public constant TOKEN_URI_DOMAIN = 0;
  uint16 public primaryChainId;

  constructor(
    address _authority,
    address _lzEndpoint,
    uint16 _primaryChainId
  )
    // Eden Dao Domain Service = Eden Dao DS = Eden Dao Deus = DAO DEUS
    ERC721("Eden Dao Domain", "DAO DEUS")
    Omnichain(_lzEndpoint)
    Authenticated(_authority)
  {
    primaryChainId = _primaryChainId;
    uint72[34] memory premint = [
      0,
      1,
      2,
      3,
      5,
      6,
      7,
      8,
      10,
      13,
      21,
      22,
      28,
      29,
      30,
      31,
      34,
      42,
      69,
      80,
      81,
      222,
      365,
      420,
      443,
      1337,
      1998,
      2001,
      4242,
      662607015, // Planck's Constant
      12345667890,
      12345667890987654321,
      2718281828459045235360, // Euler's number
      3141592653589793238462 // π
    ];
    for (uint256 i = 0; i < premint.length; i++) {
      _mint(owner, premint[i]);
    }
  }

  // ===================================
  // == SETTING AND READING TOKEN URI ==
  // ===================================
  mapping(uint256 => bytes) internal _tokenURI;

  function tokenURI(uint256 domainId)
    public
    view
    override
    returns (string memory)
  {
    return string(_tokenURI[domainId]);
  }

  function setTokenURI(uint256 domainId, bytes memory uri)
    external
    onlyOwnerOf(domainId)
  {
    _tokenURI[domainId] = uri;
  }

  // ===================================
  // ===== MINTS, BURNS, TRANSFERS =====
  // ===================================
  function mintTo(address to, uint256 domainId) external requiresAuth {
    require(currentChainId == primaryChainId, "Domains: Not on primary chain");
    _mint(to, domainId);
  }

  modifier onlyOwnerOf(uint256 domainId) {
    require(msg.sender == ownerOf[domainId], "Domain: UNAUTHORIZED");
    _;
  }

  function burn(uint256 domainId) external onlyOwnerOf(domainId) {
    _burn(domainId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public override {
    require(
      msg.sender == from ||
        isApprovedForAll[from][msg.sender] ||
        msg.sender == getApproved[id] ||
        isAuthorized(msg.sender, msg.sig), // for DAO control, later
      "Domain: UNAUTHORIZED"
    );

    require(to != address(0), "Domain: Invalid Recipient");

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
      balanceOf[from]--;
      balanceOf[to]++;
    }

    ownerOf[id] = to;

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function bridge(
    uint16 toChainId,
    address toAddress,
    uint256 domainId,
    address zroPaymentAddress,
    bytes calldata adapterParams
  ) external payable {
    require(msg.sender == ownerOf[domainId], "Domain: UNAUTHORIZED");

    _burn(domainId);

    lzSend(
      toChainId,
      abi.encode(toAddress, domainId),
      zroPaymentAddress,
      adapterParams
    );
  }

  function onReceive(
    uint16, // _fromChainId
    bytes calldata, // _fromContractAddress
    uint64, // _nonce
    bytes memory payload
  ) internal override {
    (address toAddress, uint256 domainId) = abi.decode(
      payload,
      (address, uint256)
    );
    _mint(toAddress, domainId);
  }
}