pragma solidity ^0.8.10;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UniswapV2Factory is Initializable, UUPSUpgradeable, OwnableUpgradeable, IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    mapping(address => address[]) private forRemoveGetPairMap;
    address[] private forRemoveGetPairArray;

    // **************** [WARNING] Don't modify previous vars & append new vars only ****************

    // **************** don't touch ****************
    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // **************** IUniswapV2Factory ****************
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external onlyProxy returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);

        // **************** reset function, remove this for the final product ****************
        recordResetInfo(token0, token1);
        // **************** end reset function, remove this for the final product ****************

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external onlyOwner {
        //require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    // **************** reset function, remove this for the final product ****************
    function recordResetInfo(address token0, address token1) private {
        forRemoveGetPairArray.push(token0);
        forRemoveGetPairArray.push(token1);
        forRemoveGetPairMap[token0].push(token1);
        forRemoveGetPairMap[token1].push(token0);
    }

    function reset() external onlyOwner {
        delete allPairs;
        for (uint256 i = 0; i < forRemoveGetPairArray.length; i++) {
            address token0Addr = forRemoveGetPairArray[i];
            for (uint256 j = 0; j < forRemoveGetPairMap[token0Addr].length; j++) {
                address token1Addr = forRemoveGetPairMap[token0Addr][j];
                delete getPair[token0Addr][token1Addr];
            }
            
            delete forRemoveGetPairMap[token0Addr];
        }
        
        delete forRemoveGetPairArray;
    }
    // **************** end reset function, remove this for the final product ****************
}
