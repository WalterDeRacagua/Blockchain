 // SPDX-License-Identifier: GPL-3.0
 pragma solidity 0.4.26;
 contract lab6 {
    uint[] arr;//Posición 0 de Storage
    uint sum;//Posición 1 de Storage

    function generate(uint n) external {
        for (uint i = 0; i < n; i++) {
        arr.push(i*i);
        }
    }

    function computeSum() external {
        
        sum = 0;//1 SSTORE

        /*
            Estos accesos ocurren tantas veces como el número de elementos en el array.
            Lee array.length -> 1 SLOAD
            Lee arr[i] -> 1 SLOAD
            Lee sum -> 1 SLOAD
            Escribe sum -> 1 SSTORE

            Tenemos que reducir esto.
        */
        for (uint i = 0; i < arr.length; i++) {
            sum = sum + arr[i];
        }
    }
}







