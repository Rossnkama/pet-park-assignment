//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@Openzeppelin/contracts/access/Ownable.sol";
import "./Enums.sol";

contract PetPark is Ownable {
    // = STATE VARS =
    mapping(AnimalType => uint256) public animalCounts;
    mapping(address => User) public users;

    // = STRUCTS =
    struct User {
        uint8 age;
        Gender gender;
        AnimalType animal;
        bool hasBorrowed;
        bool isRegistered;
    }

    // = EVENTS =
    event Added(AnimalType animal, uint256 amount);
    event Borrowed(AnimalType indexed animal);

    // = MODIFIERS =
    modifier hasNotBorrowed() {
        User memory _user = users[msg.sender];

        require(!_user.hasBorrowed, "Already adopted a pet");
        _;
    }

    modifier hasValidArgs(uint8 _age, Gender _gender) {
        if (_age <= 0) {
            revert("Invalid Age");
        }

        User memory _user = users[msg.sender];

        if (_user.isRegistered) {
            if (_user.gender != _gender) {
                revert("Invalid Gender");
            }
            if (_user.age != _age) {
                revert("Invalid Age");
            }
        }
        _;
    }

    modifier validMaleBorrowRequest(
        uint8 _age,
        Gender _gender,
        AnimalType _animal
    ) {
        require(
            _gender != Gender.Male ||
                _animal == AnimalType.Fish ||
                _animal == AnimalType.Dog,
            "Invalid animal for men"
        );
        _;
    }

    modifier validFemaleBorrowRequest(
        uint8 _age,
        Gender _gender,
        AnimalType _animal
    ) {
        if (_gender == Gender.Female) {
            if (_age < 40 && _animal == AnimalType.Cat) {
                revert("Invalid animal for women under 40");
            }
        }
        _;
    }

    modifier animalIsInSupply(AnimalType _animal) {
        require(animalCounts[_animal] >= 1, "Selected animal not available");
        _;
    }

    modifier hasBorrowed() {
        User memory _user = users[msg.sender];
        require(_user.hasBorrowed, "No borrowed pets");
        _;
    }

    // = IMPLEMENTATION =
    function add(AnimalType _animal, uint256 _amount) public onlyOwner {
        animalCounts[_animal] += _amount;
        emit Added(_animal, _amount);
    }

    function borrow(
        uint8 _age,
        Gender _gender,
        AnimalType _animal
    )
        public
        hasValidArgs(_age, _gender)
        hasNotBorrowed
        animalIsInSupply(_animal)
        validMaleBorrowRequest(_age, _gender, _animal)
        validFemaleBorrowRequest(_age, _gender, _animal)
    {
        animalCounts[_animal]--;

        User storage user = users[msg.sender];
        user.hasBorrowed = true;
        user.age = _age;
        user.gender = _gender;
        user.animal = _animal;
        user.isRegistered = true;

        emit Borrowed(_animal);
    }

    function giveBackAnimal() public hasBorrowed {
        User storage _user = users[msg.sender];
        animalCounts[_user.animal]++;
        _user.hasBorrowed = false;
        _user.animal = AnimalType.None;

    }
}
