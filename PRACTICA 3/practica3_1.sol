//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/*VERSIÓN CON ARRAYS*/
contract PiggyArray{

    struct Cliente{
        string nombre;
        address direccion;
        uint cantidad;
    }

    Cliente [] clientes; //Array de clientes.

    function addClient(string memory name)external payable{
       
        Cliente memory c =  Cliente(name, msg.sender,msg.value);


        uint len = bytes(name).length;
        require(len >0 , "La cadena debe ser un numero mayor que 0");


        uint pos = search(msg.sender);
        require(pos == clientes.length, "El cliente esta repetido");




        clientes.push(c);
    }


    function deposit() external payable {
       
        uint pos = search(msg.sender);


        require(pos < clientes.length, "No se ha encontrado en el array");


        clientes[pos].cantidad += msg.value;
    }

    function search(address sender) view internal returns (uint){


        uint pos = clientes.length;


        for(uint i=0; i< clientes.length; i++){
            if(sender == clientes[i].direccion){
                pos = i;
            }
        }


        return pos;
    }

    function withdraw(uint amountInWei)external{


        uint pos = search(msg.sender);


        require(pos < clientes.length, "No se ha encontrado en el array");
        require(clientes[pos].cantidad >= amountInWei, "No hay suficiente saldo");
       
        // Transferir la cantidad solicitada al remitente
        clientes[pos].cantidad -= amountInWei;
        payable(clientes[pos].direccion).transfer(amountInWei);
    }

    function getBalance()external view returns (uint){
        uint pos = search(msg.sender);


        require(pos < clientes.length, "No se ha encontrado en el array");
        return clientes[pos].cantidad;
    }
}
