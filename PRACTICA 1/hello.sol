// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 < 0.8.0;

contract hello {

    event Print(string message);

    function helloWorld() public{
        emit Print("Hello, World!");
    }
}