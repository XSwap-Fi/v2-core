pragma solidity ^0.8.10;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UniswapV2FactoryProxy is ERC1967Proxy {
    /*
     * _logic: the implementation contract
     * _date: the call data to initialize _logic (should be 0x8129fc1c for calling UniswapV2Query.initialize())
     */
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) payable {}
}
