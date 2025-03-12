// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library ArrayUtils {


    //Es pure y no es view porque ni modifica ni lee el estado de nada. Es más eficiente en gas.
    function contains(string[] memory arr, string calldata val) internal pure returns(bool){


        for (uint i =0; i < arr.length; i++)
        {
            if (keccak256(bytes(arr[i])) == keccak256(bytes(val))) {
                return true;
            }
        }


        return false;
    }


    //Los uint no necesitan ponerse memory ni nada
    function increment(uint[] memory arr, uint8  per) internal pure {


        for (uint i=0; i< arr.length; i++)
        {
            arr[i] += arr[i] * (per/100);  
        }
    }


    function sum(uint[] memory arr) internal pure returns (uint){


        uint suma=0;


        for (uint i=0; i< arr.length; i++)
        {
            suma += arr[i];  
        }
       
        return suma;
    }
}
