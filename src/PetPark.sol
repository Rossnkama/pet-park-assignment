//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@Openzeppelin/contracts/access/Ownable.sol";
import "./Enums.sol";

contract PetPark is Ownable {
    // ====== STATE VARS ======
    mapping(AnimalType => uint) public animalCount;

    // ====== EVENTS ======
    event Added(AnimalType indexed animal, uint256 amount);

    function add(AnimalType _animal, uint256 _amount) public onlyOwner {
        animalCount[_animal] += _amount;
        emit Added(_animal, _amount);
    }
}
