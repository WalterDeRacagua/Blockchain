// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Librería ERC20 de OpenZeppelin 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IExecutableProposal {
    function executeProposal(uint proposalId, uint numVotes, uint numTokens) external payable;
}


contract QuadraticVoting{ //Contrato para la votación cuadrática.

    /*VARIABLES*/

    //Contrato que gestiona la votación.
    uint tokenCost; //Precio en Wei de cada token
    
    uint numTokens; //Número máximo de tokens que se van a poner a la venta para las votaciones
    
    address _owner; //Owner del contrato. Es el que crea el contrato.

    mapping (address=> uint) private addressTokens; //Número de tokens que puede comprar cada address. 

    uint proposalId; //Variable que va aumentando para almacenar los ids de las propuestas.

    bool _isOpened; //Almacenamos si la votación está abierta.

    mapping (uint => Proposal) public proposals;//Id de la propuesta-> propuesta


    struct Proposal {
        string _title; //Título de la propuesta.
        string _description;
        uint _participants; //Número de participantes
        uint _budget;
        uint _votes;
        uint _umbral;
        /*Address del contrato que debe implementar la interfaz IExecutableProposal.*/
        address _contractProposal; //Será el receptor del dinero presupuestado en caso de ser aprobada la propuesta.
    }

    //constructor de quadratic voting.
    constructor() {
        _owner = msg.sender; 
        _isOpened = false;
        proposalId=0; //Inicializamos ids a 0
    }
    
    /*MODIFICADORES*/

    modifier onlyOwner() { 
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier onlyAfterOpen() {
        require(_isOpened, "Voting is not opened");
        _;
    }

    function openVoting () external onlyOwner {

        //Marcamos las votaciones como abiertas.
        _isOpened=true;
    }

    function addParticipant () public payable{
        
        //Cuando se inscribe el participante debe transferir Ether para comprar Tokens (al menos uno).
        require(msg.value >= tokenCost, "No suficient funds");
        
        //Se deben crear y asignar tokens en función del importe.
        addressTokens[msg.sender] = msg.value/tokenCost;
    }

    function removeParticipant() public {

        //Eliminamos al participante.
        delete addressTokens[msg.sender];

    }

    function addProposal (string calldata title, string calldata description, uint  budget, address contr) public onlyAfterOpen  returns (uint) {

        Proposal memory p = Proposal(title, description, 0, budget,0,0, contr);
        proposalId++;
        proposals[proposalId] = p; //Asignamos a la propuesta un Id.

        return proposalId;
    }

    function cancelProposal (uint idProposal) public onlyAfterOpen {

    }

    /*Tendré que cambiar lo de view porque no es inmutable.*/
    function buyTokens() view public{

        //Permite a participante ya inscrito comprar más tokens.
        require(addressTokens[msg.sender] != 0, "Este participante no esta inscrito en la votacion");

        /*INFORMARME MÁS SOBRE ESTA FUNCIÓN*/
    }

    function sellTokens () view public {

        //No puede llamar a esta función si no tiene tokens.
        require(addressTokens[msg.sender]!= 0);

        /*Aquí tendríamos que reducir la cantidad de tokens del msg.sender.*/
        /*Le debemos de ingresar el Ether correspondiente a la cantidad de tokens que devuelve.*/
    }

    function getERC20() external returns (address) {


    }

    /*De tipo view porque simplemente devolvemos un array con los identificadores de propuestas DE FINANCIACIÓN PENDIENTES*/
    function getPendingProposals() external view onlyAfterOpen returns (uint[] memory pendingIdentifiers){



    }

    /*De tipo view porque simplemente devolvemos un array con los identificadores de propuestas APROBADAS*/
    function getApprovedProposals() external view onlyAfterOpen returns (uint[] memory approvedIdentifiers){


    
    }


    function getProposalInfo (uint idProposal) external view onlyAfterOpen returns (Proposal memory p){

        return proposals[idProposal]; //Devuelve la propuesta con el id pasado por parámetro.
    }

    /*NO DICE NADA PERO YO SUPONGO QUE HAY QUE LLAMAR SOLO SI LA VOTACIÓN ESTÁ ABIERTA.*/
    function stake (uint idProposal, uint voteAmount) external onlyAfterOpen {
        
    
    }

    /* 
    Calcula los tokens
    necesarios para depositar los votos que se van a depositar y comprueba que el participante ha cedido
    (con approve) el uso de esos tokens a la cuenta del contrato de la votacion.
    */
    function approve () external view {

    }

    function withdrawFromProposal (uint voteAmount, uint idProposal) public {
        //Retira si es posible esa cantidad de votos por el participante que invoca  esta función
    }


    function _checkAndExecuteProposal () internal {
        //Si se puede ejecuta execute proposal del contrato.

    }

    function closeVoting () external onlyOwner {

        _isOpened =false;
    }
    
}