// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Librería ERC20 de OpenZeppelin 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "./VotingContract.sol";

/*CREO QUE NO ES NECESARIO ESTE IMPORT MÁS QUE NADA PORQUE ERC20 CUENTA YA CON _burn*/
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IExecutableProposal {
    function executeProposal(uint proposalId, uint numVotes, uint numTokens) external payable;
}

contract QuadraticVoting{ //Contrato para la votación cuadrática.

    //Instancia del contrato ERC20
    VotingContract public votingContract;

    uint256 totalBudget; //Presupuesto total en Weis para las votaciones

    address _owner; //Owner del contrato. Es el que crea el contrato.


    bool isVotingOpen; //Almacenamos si la votación está abierta.

    /*PARTICIPANTES*/
    uint256 public numParticipants;
    mapping (address=>bool) public participants;//Para ver si están registrados

    struct Proposal {
        uint256 id;//Identificador único
        string _title; //Título de la propuesta.
        string _description;
        uint256 _participants; //Número de participantes
        uint256 _budget;//Presupuesto de la propuesta.
        uint256 _votes; //Numero de votos totales en la propuesta
        uint256 _umbral;
        /*Address del contrato que debe implementar la interfaz IExecutableProposal.*/
        address _contractProposal; //Será el receptor del dinero presupuestado en caso de ser aprobada la propuesta.
        address _creator;
        mapping (address => uint256) _votes_participant; //Número de votos por participante.
        bool _isSignalign; //Si no es de signalign será financiera
        bool _isApproved;//Se ha aprobado la propuesta
        bool _isCanceled; //Se ha cancelado la propuesta.
    }

    mapping (uint => Proposal) public proposals;//Id de la propuesta-> propuesta
    uint256[] public proposalsArray;

    uint256 public numProposals; //Numero de propuestas
    uint256 public numPendingProposals; //Propuestas de financiación pendientes.

    //constructor de quadratic voting.
    constructor(uint256 _tokenPrice, uint256 _maxTokens) {

        /*No se si  es correcto tener en el constructor requieres*/
        require(_tokenPrice >0, "El precio de los tokens debe ser mayor que cero");
        require(_maxTokens>0, "El maximo numero de tokens a emitir debe ser mayor que cero");

        _owner = msg.sender; 

        isVotingOpen = false;
        /*Podemos sacar despues el precio y el max de los getter.*/
        votingContract = new VotingContract("DAO Vote Token", "DVT", _tokenPrice, _maxTokens);
        numProposals=0;
        numPendingProposals=0;
        totalBudget=0;
    }
    
    /*MODIFICADORES*/

    modifier onlyOwner() { 
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier onlyAfterOpen() {
        require(isVotingOpen, "Voting is not opened");
        _;
    }

    function openVoting () external payable onlyOwner {
        
        //Vamos a comprobar que no esté abierta esta votación
        require(!isVotingOpen, "La votacion ya esta abierta");

        //Comprobamos que el presupuesto inicial (msg.value) sea mayor que 0.
        require(msg.value >0, "El presupuesto inicial debe ser mayor que cero");

        //Presupuesto total
        totalBudget = msg.value;
        
        //Marcamos las votaciones como abiertas.
        isVotingOpen=true;
    }

    function addParticipant () external  payable{
        
        //Cuando se inscribe el participante debe transferir Ether para comprar Tokens (al menos uno).
        require(msg.value >= votingContract.getTokenPrice(), "No estas aportando suficiente Ether como para comprar tokens");
        
        //Comprobamos que no esté registrado ya el participante.
        require(!participants[msg.sender], "Participante ya esta registrado.");

        //Calculamos cuántos tokens podemos emitir con value aportado por el participante
        uint256 numTokens= msg.value/votingContract.getTokenPrice();
        require(numTokens>=1, "Necesitas poder comprar al menos un token");

        //Registrar participante
        participants[msg.sender]=true;
        numParticipants++;        

        //Emitimos los tokens
        votingContract.mint(msg.sender, numTokens);
    }

    function removeParticipant() public {

        //Eliminamos al participante.
        require(participants[msg.sender], "Particiapante no registrado");

        //Eliminar participante
        participants[msg.sender]=false;
        numParticipants--;        
    }

    function addProposal (string calldata title, string calldata description, uint256  budget, address proposalContract) public onlyAfterOpen  returns (uint256) {

        require(isVotingOpen, "La votacion debe estar abierta");
        require(participants[msg.sender], "Debes inscribirte como participante para poder crear una propuesta");
        require(proposalContract != address(0) , "La direccion del contrato no es valida");
        require(bytes(title).length >0 , "El titulo de la propuesta no puede ser vacio");
        require(bytes(description).length>0, "La descripcion de la propuesta no puede ser vacia");

        //Aumentamos el numero de propuestas
        uint256 proposalId =numProposals;
        numProposals++;

        Proposal storage newProposal=proposals[proposalId];
        newProposal.id = proposalId;
        newProposal._title = title;
        newProposal._description= description;
        newProposal._participants=0;
        newProposal._budget= budget; //Ahora estamos poniendo el presupuesto.
        newProposal._contractProposal= proposalContract;
        newProposal._creator=msg.sender;

        if (budget > 0)  {
            newProposal._isSignalign= false;
            /*Aumentamos el número de propuestas pendientes*/
            numPendingProposals++;
        }
        else {
            newProposal._isSignalign= true ;
        }

        newProposal._votes=0;
        newProposal._isApproved=false;
        newProposal._isCanceled=false;

        if (!newProposal._isSignalign) {
            proposalsArray.push(proposalId);    
        }
        return proposalId;
    }
    
    function cancelProposal (uint idProposal) public onlyAfterOpen {
        require(idProposal > numProposals, "No existe esa propuesta");
        require(msg.sender == proposals[idProposal]._creator, "No puedes cancelar la propuesta si no eres el creador de la misma");
        require(!proposals[idProposal]._isApproved, "No se pueden aprobar propuestas ya aprobadas.");
        require(!proposals[idProposal]._isCanceled, "No se puede cancelar si la propuesta ya ha sido cancelada anteriormente");

        proposals[idProposal]._isCanceled=true;//Cancelamos la propuesta

        //Si es de financiación...
        if (!proposals[idProposal]._isSignalign){ 
            numPendingProposals--;
        }

        /*FALTA DEVOLVER LOS TOKENS COMPRADOS.*/
    }

    /*Tendré que cambiar lo de view porque no es inmutable.*/
    function buyTokens() public payable {
        require(participants[msg.sender], "Para comprar tokens necesitas haberte inscrito como participante");
        require(msg.value >= votingContract.getTokenPrice(), "Debes enviar el Ether necesario para poder comprar al menos un token");


        /*Revisar esto porque hay que tener en cuenta los que ha ha comprado.*/
        uint256 boughtTokens = msg.value/ votingContract.getTokenPrice();
        require(boughtTokens >= 1, "Necesitas comprar al menos un Token");

        
    /*
    PARA RECORDARLO YO: El término "mintear" proviene del inglés "mint", que significa "acuñar" o "crear"
    en el contexto de monedas o activos
    */
        votingContract.mint(msg.sender, boughtTokens);
    }

    function sellTokens (uint256 tokensToReturn) view public {
        require(participants[msg.sender], "Para comprar tokens necesitas haberte inscrito como participante");
        require(tokensToReturn > 0, "No puedes vender una cantidad inferior a 1 token.");
        require(votingContract.balanceOf(msg.sender)>= tokensToReturn, "No puedes vender mas tokens de los que posees");

        /*Aquí tendríamos que reducir la cantidad de tokens del msg.sender. Hay que revisar porque es cuadrático y eso aun 
        no lo estamos barajando*/

        uint256 refund = tokensToReturn * votingContract.getTokenPrice();
        require(address(this).balance >= refund, "El contrato no tiene recursos para devolverte el Ether.");

        votingContract.burn(msg.sender, tokensToReturn); //Los borramos de la cuenta del contrato para no estar volviendo

        /*Le debemos de ingresar el Ether correspondiente a la cantidad de tokens que devuelve.*/
        payable(msg.sender).transfer(refund); //Le devolvemos el valor de la devolución, de momento ese valor esta mal porque no lo calculamos correctamente
    }

    function getERC20() external view returns (address) {

        //Getter de toda la vida que devuelve el address del contrato ERC20. No creo que tenga mayor misterio que esto.
        return address(votingContract);
    }

    /*De tipo view porque simplemente devolvemos un array con los identificadores de propuestas DE FINANCIACIÓN PENDIENTES*/
    function getPendingProposals() external view onlyAfterOpen returns (uint[] memory pendingIdentifiers){

                
    }

    /*De tipo view porque simplemente devolvemos un array con los identificadores de propuestas APROBADAS*/
    function getApprovedProposals() external view onlyAfterOpen returns (uint[] memory approvedIdentifiers){


    
    }


    function getProposalInfo (uint idProposal) external view onlyAfterOpen returns (Proposal memory p){


        
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

        isVotingOpen =false;
    }
    
}