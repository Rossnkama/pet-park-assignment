// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PetPark.sol";


contract PetParkTest is Test, PetPark {
    PetPark petPark;
    
    address testOwnerAccount;

    address testPrimaryAccount;
    address testSecondaryAccount;

    function setUp() public {
        petPark = new PetPark();

        testOwnerAccount = msg.sender;
        testPrimaryAccount = address(0xABCD);
        testSecondaryAccount = address(0xABDC);
    }

    function testOwnerCanAddAnimal() public {
        petPark.add(AnimalType.Fish, 5);
    }

    function testCannotAddAnimalWhenNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(0));
        petPark.add(AnimalType.Fish, 5);
    }

    function testExpectedAnimalCountssAfterAdditions() public {
        petPark.add(AnimalType.Fish, 10);
        petPark.add(AnimalType.Fish, 10);
        petPark.add(AnimalType.Dog, 3);

        assertEq(petPark.animalCounts(AnimalType.Fish), 20);
        assertEq(petPark.animalCounts(AnimalType.Dog), 3);
    }

    function testCannotAddWhenMaxUINT() public {
        petPark.add(AnimalType.Dog, UINT256_MAX);
        vm.expectRevert(stdError.arithmeticError);
        petPark.add(AnimalType.Dog, 1);
    }

    function testExpectEmitAddEvent() public {
        vm.expectEmit(true, true, false, false);
        // Fields not indexed
        emit Added(AnimalType.Rabbit, 3);
        petPark.add(AnimalType.Rabbit, 3);
    }

    function testCannotBorrowWhenAgeZero() public {
        petPark.add(AnimalType.Fish, 5);
        vm.expectRevert("Invalid Age");
        petPark.borrow(0, Gender.Male, AnimalType.Fish);
    }

    function testCannotBorrowUnavailableAnimal() public {
        vm.expectRevert("Selected animal not available");
        petPark.borrow(24, Gender.Male, AnimalType.Fish);
    }

    function testCannotBorrowCatForMen() public {
        petPark.add(AnimalType.Cat, 5);

        vm.expectRevert("Invalid animal for men");
        petPark.borrow(24, Gender.Male, AnimalType.Cat);
    }

    function testCannotBorrowRabbitForMen() public {
        petPark.add(AnimalType.Rabbit, 5);

        vm.expectRevert("Invalid animal for men");
        petPark.borrow(24, Gender.Male, AnimalType.Rabbit);
    }

    function testCannotBorrowParrotForMen() public {
        petPark.add(AnimalType.Parrot, 5);

        vm.expectRevert("Invalid animal for men");
        petPark.borrow(24, Gender.Male, AnimalType.Parrot);
    }

    function testCannotBorrowForWomenUnder40() public {
        petPark.add(AnimalType.Cat, 5);

        vm.expectRevert("Invalid animal for women under 40");
        petPark.borrow(24, Gender.Female, AnimalType.Cat);
    }

    function testCannotBorrowTwiceAtSameTime() public {
        petPark.add(AnimalType.Fish, 5);
        petPark.add(AnimalType.Cat, 5);

        vm.prank(testPrimaryAccount);
        petPark.borrow(24, Gender.Male, AnimalType.Fish);

		vm.expectRevert("Already adopted a pet");
        vm.prank(testPrimaryAccount);
        petPark.borrow(24, Gender.Male, AnimalType.Fish);

        vm.expectRevert("Already adopted a pet");
        vm.prank(testPrimaryAccount);
        petPark.borrow(24, Gender.Male, AnimalType.Cat);
    }

    function testCannotBorrowWhenAddressDetailsAreDifferent() public {
        petPark.add(AnimalType.Fish, 5);

        vm.prank(testPrimaryAccount);
        petPark.borrow(24, Gender.Male, AnimalType.Fish);

		vm.expectRevert("Invalid Age");
        vm.prank(testPrimaryAccount);
        petPark.borrow(23, Gender.Male, AnimalType.Fish);

		vm.expectRevert("Invalid Gender");
        vm.prank(testPrimaryAccount);
        petPark.borrow(24, Gender.Female, AnimalType.Fish);

        vm.expectRevert("Already adopted a pet");
        vm.prank(testPrimaryAccount);
        petPark.borrow(24, Gender.Male, AnimalType.Fish);
    }

    function testExpectEmitOnBorrow() public {
        petPark.add(AnimalType.Fish, 5);
        vm.expectEmit(true, false, false, false);

        emit Borrowed(AnimalType.Fish);
        petPark.borrow(24, Gender.Male, AnimalType.Fish);
    }

    function testBorrowCountDecrement() public {
        petPark.add(AnimalType.Dog, 2);
        assertEq(petPark.animalCounts(AnimalType.Dog), 2);

        petPark.borrow(24, Gender.Male, AnimalType.Dog);
        assertEq(petPark.animalCounts(AnimalType.Dog), 1);
    }

    function testCannotGiveBack() public {
        vm.expectRevert("No borrowed pets");
        petPark.giveBackAnimal();
    }

    function testPetCountIncrement() public {
        petPark.add(AnimalType.Fish, 5);

        petPark.borrow(24, Gender.Male, AnimalType.Fish);
        uint reducedPetCount = petPark.animalCounts(AnimalType.Fish);

        petPark.giveBackAnimal();
        uint currentPetCount = petPark.animalCounts(AnimalType.Fish);

		assertEq(reducedPetCount, currentPetCount - 1);
    }
}