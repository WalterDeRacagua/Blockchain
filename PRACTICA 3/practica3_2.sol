//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/*VERSIÓN CON MAPAS*/
contract PiggyMap{

    struct Cliente{
        string nombre;
        uint cantidad;
    }

    mapping (address => Cliente) clientes; //Mapa con clave address y con valor Cliente {nombre y cantidad}.

    function addClient(string memory name)external payable{
       
        uint len = bytes(name).length;
        require(len >0 , "La cadena debe ser un numero mayor que 0");

        require(bytes(clientes[msg.sender].nombre).length == 0, "El cliente esta repetido"); //Con esto comprobamos si está

        clientes[msg.sender] = Cliente(name, msg.value);
    }


    function deposit() external payable {
       
        require(bytes(clientes[msg.sender].nombre).length > 0, "No se ha encontrado en el array");

        clientes[msg.sender].cantidad += msg.value;
    }

    //Esta función creo que es innecesaria
    /*
    function search(address sender) view internal returns (uint){


        uint pos = clientes.length;


        for(uint i=0; i< clientes.length; i++){
            if(sender == clientes[i].direccion){
                pos = i;
            }
        }


        return pos;
    }
*/
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
}
