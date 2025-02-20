//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/*VERSIÓN CON MAPAS*/
contract PiggyMap2{

    struct Cliente{
        string nombre;
        uint cantidad;
    }

    mapping (address => Cliente) clientes; //Mapa con clave address y con valor Cliente {nombre y cantidad}.
    address [] claves_map;

    function addClient(string memory name)external payable{
       
        uint len = bytes(name).length;
        require(len >0 , "La cadena debe ser un numero mayor que 0");

        require(bytes(clientes[msg.sender].nombre).length == 0, "El cliente esta repetido"); //Con esto comprobamos si está

        clientes[msg.sender] = Cliente(name, msg.value);
       
        //Agregamos dirección al array de direcciones.
        claves_map.push(msg.sender);//Push mas eficiente
    }


    function deposit() external payable {
       
        require(bytes(clientes[msg.sender].nombre).length > 0, "No se ha encontrado en el array");

        clientes[msg.sender].cantidad += msg.value;
    }

    function withdraw(uint amountInWei)external{


        require(bytes(clientes[msg.sender].nombre).length > 0, "No se ha encontrado en el array");
        require(clientes[msg.sender].cantidad >= amountInWei, "No hay suficiente saldo");
       
        // Transferir la cantidad solicitada al remitente
        clientes[msg.sender].cantidad -= amountInWei;
        payable(msg.sender).transfer(amountInWei);
    }

    function getBalance()external view returns (uint){

        require(bytes(clientes[msg.sender].nombre).length > 0, "No se ha encontrado en el array");
        return clientes[msg.sender].cantidad;
    }

    function checkBalances()external view returns(bool){
        uint balanceT=0;

        //Bucle que recorre los clientes para sumar los balances
        for(uint i=0; i< claves_map.length; i++){
             address dir_cliente = claves_map[i];
             balanceT += clientes[dir_cliente].cantidad;
        }

        //Devuelve true si la suma es igual al balance del contrato
        return balanceT ==address(this).balance; 
    }
}
