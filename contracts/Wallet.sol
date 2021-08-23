pragma solidity 0.8.7;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {

  using SafeMath for uint256;

  struct Token {
  //  uint256 arrIndex;
    bytes32 ticker;
    address tokenAddress;
  }

  bytes32[] public tokenList;
  mapping(bytes32 => Token) public tokenMapping;

  mapping(address => mapping(bytes32 => uint256)) public balances; // bytes32 is the token symbol

  modifier tokenExists(bytes32 _ticker) {
    require(tokenMapping[_ticker].tokenAddress != address(0), "Token does not exist");
    _;
  }

  function addToken(bytes32 _ticker, address _tokenAddress) onlyOwner external {
    tokenMapping[_ticker] = Token(_ticker, _tokenAddress);
    tokenList.push(_ticker);
  }

  function deposit(uint _amount, bytes32 _ticker) tokenExists(_ticker) external {


    uint256 ogBalance = balances[msg.sender][_ticker];
    IERC20(tokenMapping[_ticker].tokenAddress).transferFrom(msg.sender, address(this), _amount);
    balances[msg.sender][_ticker] = balances[msg.sender][_ticker].add(_amount);

    assert(balances[msg.sender][_ticker] == ogBalance + _amount);
  }

  function withdraw(uint256 _amount, bytes32 _ticker) tokenExists(_ticker) external {
    require(balances[msg.sender][_ticker] >= _amount, "Balance is not sufficient");

    uint256 ogBalance = balances[msg.sender][_ticker];
    balances[msg.sender][_ticker] = balances[msg.sender][_ticker].sub(_amount);
    IERC20(tokenMapping[_ticker].tokenAddress).transfer(msg.sender, _amount);

    assert(balances[msg.sender][_ticker] == ogBalance - _amount);
  }
}
