 // SPDX-License-Identifier: GPL-3.0
 pragma solidity 0.4.26;
contract lab6_mejorado{

    uint[] arr;
    uint sum=0;


   
    function generate(uint n) external {
        for (uint i = 0; i < n; i++) {
        arr.push(i*i);
        }
    }
    function computeSum() external {
       
        uint[] memory array = new uint[](arr.length);
        array = arr;
        uint suma_acum=0;
        uint length = arr.length;
       
       
        for (uint i = 0; i < length; i++) {
            suma_acum = suma_acum + array[i];
        }


        sum = suma_acum;
    }
}