// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Librería ERC20 de OpenZeppelin 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "./VotingContract.sol";

/*CREO QUE NO ES NECESARIO ESTE IMPORT MÁS QUE NADA PORQUE ERC20 CUENTA YA CON _burn*/
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IExecutableProposal {
    function executeProposal(uint256 proposalId, uint256 numVotes, uint256 numTokens) external payable;
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

        /*Añado este atributo para no tener que hacer un for en la función de checkAndExecuteProposal*/

        uint256 _numTokens; //Número total de tokens que hay en la propuesta


        /*Necesitamos añadir un array con los addresses de los votantes para recorrerlos en la función de closeVoting.*/
        address[] _voters;
    }

    /*Estructura auxiliar porque solidity no permite devolver mappings en funciones y Proposal tiene un map 
    (Veremos si lo podemos solucionar para tener únicamente una estructura). Lo necesitamos para el getProposalInfo
    */
    struct ProposalInfo {
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
        bool _isSignalign; //Si no es de signalign será financiera
        bool _isApproved;//Se ha aprobado la propuesta
        bool _isCanceled; //Se ha cancelado la propuesta.

        uint256 _numTokens; //Número total de tokens que hay en la propuesta
    }

    mapping (uint => Proposal) public proposals;//Id de la propuesta-> propuesta
    uint256[] public proposalsArray;//Array con los identificadores de las propuestas

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
    
    /* MODIFICADORES */

    modifier onlyOwner() { 
        require(msg.sender == _owner, "Debes ser el owner del contrato para poder hacer esto.");
        _;
    }


    modifier onlyAfterOpen() {
        require(isVotingOpen, "La votacion tiene que estar abierta");
        _;
    }

    



    /* FUNCIONES */

    function openVoting () external payable onlyOwner {
        
        //Vamos a comprobar que no esté abierta esta votación
        require(!isVotingOpen, "La votacion ya esta abierta, no puedes volver a abrirla");

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

        //De momento no hay ni votos ni tokens.
        newProposal._votes=0;
        newProposal._numTokens=0; 

        //La propuesta no se ha cancelado ni aprobado
        newProposal._isApproved=false;
        newProposal._isCanceled=false;

        //Tenemos que meter dentro del array todas las propuestas, luego en los getters comprobamos el resto de cosas.
        proposalsArray.push(proposalId);    

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

        /*NO TENEMOS QUE QUITAR DEL ARRAY PORQUE NO SE PUEDE HACER UN POP COMO EN JAVA */

        /*FALTA DEVOLVER LOS TOKENS COMPRADOS.*/
    }

    function buyTokens() public payable {
        require(participants[msg.sender], "Para comprar tokens necesitas haberte inscrito como participante");
        require(msg.value >= votingContract.getTokenPrice(), "Debes enviar el Ether necesario para poder comprar al menos un token");


        uint256 boughtTokens = msg.value/ votingContract.getTokenPrice();
        require(boughtTokens >= 1, "Necesitas comprar al menos un Token");

        
        /*
        PARA RECORDARLO YO: El término "mintear" proviene del inglés "mint", que significa "acuñar" o "crear"
        en el contexto de monedas o activos
        */
        votingContract.mint(msg.sender, boughtTokens);
    }

    function sellTokens (uint256 tokensToReturn)  public {
        require(participants[msg.sender], "Para comprar tokens necesitas haberte inscrito como participante");
        require(tokensToReturn > 0, "No puedes vender una cantidad inferior a 1 token.");
        require(votingContract.balanceOf(msg.sender)>= tokensToReturn, "No puedes vender mas tokens de los que posees");

        uint256 refund = tokensToReturn * votingContract.getTokenPrice();
        require(address(this).balance >= refund, "El contrato no tiene recursos para devolverte el Ether.");

        votingContract.burn(msg.sender, tokensToReturn); //Los borramos de la cuenta del contrato para no estar volviendo

        /*100% TENEMOS QUE CAMBIAR ESTE TRANSFER PORQUE LIMITA LA CANTIDAD DE GAS*/
        payable(msg.sender).transfer(refund); //Le devolvemos el valor de la devolución, de momento ese valor esta mal porque no lo calculamos correctamente
    }

    function getERC20() external view returns (address) {

        //Getter de toda la vida que devuelve el address del contrato ERC20. No creo que tenga mayor misterio que esto.
        return address(votingContract);
    }

    /*De tipo view porque simplemente devolvemos un array con los identificadores de propuestas DE FINANCIACIÓN PENDIENTES*/
    function getPendingProposals() internal view onlyAfterOpen returns (uint[] memory ){

        uint256[] memory tempIDs = new uint256[](proposalsArray.length);//Queremos un array mínimamente del tamaño de las peticiones pendientes
        uint256 numPending=0;
        //Ese tamaño no es el tamaño real que queremos, tenemos que meter los elementos que queramos y después volver a meterlos en otro array que tenga el tamaño real

        /*ESTOS FORS QUIZÁS PODEMOS REDUCIR LA CANTIDAD DE GAS CON YUL*/
        for (uint256 i=0; i< proposalsArray.length; i++) 
        {
            uint256 p_id= proposalsArray[i];//Sacamos el id

            //Tenemos que comprobar que sea de financiación y que además no haya sido aprobada NI cancelada
            if (!proposals[p_id]._isSignalign && !proposals[p_id]._isApproved && !proposals[p_id]._isCanceled) {
                //Metemos el p_id en caso de que esto suceda porque significa que esta pending
                tempIDs[numPending]= p_id ;
                numPending++;
            }   
        }

        //Array del tamaño real
        uint256[] memory pendingProposalsResult = new uint256[](numPending);

        for (uint256 i=0; i<numPending; i++) 
        {
            pendingProposalsResult[i]=tempIDs[i];
        }

        return pendingProposalsResult;
    }

    /*De tipo view porque simplemente devolvemos un array con los identificadores de propuestas APROBADAS*/
    function getApprovedProposals() internal view onlyAfterOpen returns (uint[] memory ){
        
        uint256[] memory tempIDs = new uint256[](proposalsArray.length);//Queremos un array mínimamente del tamaño de las peticiones pendientes
        uint256 numPending=0;
        //Ese tamaño no es el tamaño real que queremos, tenemos que meter los elementos que queramos y después volver a meterlos en otro array que tenga el tamaño real

        /*ESTOS FORS QUIZÁS PODEMOS REDUCIR LA CANTIDAD DE GAS CON YUL*/
        for (uint256 i=0; i< proposalsArray.length; i++) 
        {
            uint256 p_id= proposalsArray[i];//Sacamos el id

            //Tenemos que comprobar que sea de financiación y que además haya sido aprobada 
            if (!proposals[p_id]._isSignalign && proposals[p_id]._isApproved) {
                //Metemos el p_id en caso de que esto suceda porque significa que esta pending
                tempIDs[numPending]= p_id;
                numPending++;
            }   
        }

        //Array del tamaño real
        uint256[] memory approvedProposalsResult = new uint256[](numPending);

        for (uint256 i=0; i<numPending; i++) 
        {
            approvedProposalsResult[i]=tempIDs[i];
        }

        return approvedProposalsResult;
    }

    function getSignalingProposals() internal view onlyAfterOpen returns (uint[] memory ){
        
        uint256[] memory tempIDs = new uint256[](proposalsArray.length);//Queremos un array mínimamente del tamaño de las peticiones pendientes
        uint256 numPending=0;
        //Ese tamaño no es el tamaño real que queremos, tenemos que meter los elementos que queramos y después volver a meterlos en otro array que tenga el tamaño real

        /*ESTOS FORS QUIZÁS PODEMOS REDUCIR LA CANTIDAD DE GAS CON YUL*/
        for (uint256 i=0; i< proposalsArray.length; i++) 
        {
            uint256 p_id= proposalsArray[i];//Sacamos el id

            //Tenemos que comprobar que sea de signalign 
            if (proposals[p_id]._isSignalign) {
                //Metemos el p_id en caso de que esto suceda porque significa que esta pending
                tempIDs[numPending]= p_id;
                numPending++;
            }   
        }

        //Array del tamaño real
        uint256[] memory signalignProposalsResult = new uint256[](numPending);

        for (uint256 i=0; i<numPending; i++) 
        {
            signalignProposalsResult[i]=tempIDs[i];
        }

        return signalignProposalsResult;

    }


    function getProposalInfo (uint256 idProposal) external view onlyAfterOpen returns (ProposalInfo memory){
        require(idProposal < numProposals, "No existe esa propuesta");
        
        //Propuesta que vamos a devolver.
        ProposalInfo memory p_info;
        
        /*Asignamos todo menos las votaciones*/
        p_info.id = idProposal;
        p_info._budget= proposals[idProposal]._budget;
        p_info._contractProposal=  proposals[idProposal]._contractProposal;
        p_info._creator =  proposals[idProposal]._creator;
        p_info._description =  proposals[idProposal]._description;
        p_info._isApproved =  proposals[idProposal]._isApproved;
        p_info._isCanceled =  proposals[idProposal]._isCanceled;
        p_info._isSignalign =  proposals[idProposal]._isSignalign;
        p_info._participants =  proposals[idProposal]._participants;
        p_info._title =  proposals[idProposal]._title;
        p_info._umbral =  proposals[idProposal]._umbral;
        
        return p_info;
    }

    /*NO DICE NADA PERO YO SUPONGO QUE HAY QUE LLAMAR SOLO SI LA VOTACIÓN ESTÁ ABIERTA.*/
    function stake (uint256 idProposal, uint256 voteAmount) external onlyAfterOpen {
        require(idProposal < numProposals, "No existe esa propuesta");
        require(participants[msg.sender], "Para participar tienes que estar registrado como participante de la DAO!");
        require(voteAmount >0, "No puedes depositar menos de 1 voto. Como vas a votar sin votar?");
        require(!proposals[idProposal]._isCanceled, "No puedes votar sobre una propuesta que ya ha sido cancelada");
        require(!proposals[idProposal]._isApproved, "La propuesta ya ha sido aprovada. Por tanto no puedes votar en ella");

        /*
        Una vez estas comprobaciones, vamos a ver cuántos votos ha hecho ya el participante para comprobar los tokens
        que necesita para realizar la propuesta. 
        */

        uint256 currentVotes= proposals[idProposal]._votes_participant[msg.sender];
        uint256 totalVotes= currentVotes + voteAmount;//Votos totales que tendra el participante.

        //¿Cuántos tokens necesitará?
        uint256 tokensNeeded = (totalVotes*totalVotes)-(currentVotes*currentVotes);

        require(IERC20(address(votingContract)).allowance(msg.sender,address(this))>= tokensNeeded, "No tienes suficientes tokens para votar");

        bool success = IERC20(address(votingContract)).transferFrom(msg.sender, address(this), tokensNeeded);
        require(success, "La transferencia de Tokens ha fallado");

        //Actualizamos los votos y tokens si ha ido todo guay
        proposals[idProposal]._votes_participant[msg.sender]= totalVotes ; 
        proposals[idProposal]._votes+= voteAmount;
        proposals[idProposal]._numTokens += tokensNeeded;
    }
    
    function withdrawFromProposal (uint256 voteAmount, uint256 idProposal) external onlyAfterOpen {
        require(idProposal < numProposals, "La propuesta que estas pasando no existe");
        require(participants[msg.sender], "Debes darte de alta como participante para ejecutar esta funcion");
        require(voteAmount >0, "Necesitas dejar un voto por lo menos."); 
        require(!proposals[idProposal]._isCanceled, "La propuesta sobre la que quieres retirar votos ya ha sido cancelada");
        require(!proposals[idProposal]._isApproved, "La propuesta ya ha sido aprobada");
        require(proposals[idProposal]._votes_participant[msg.sender] >= voteAmount, "Estas intentando retirar mas votos de los que has realizado" );       

        //Calcular cuántos votos tenemos ahora, y con cuantos nos vamos a quedar tras retirar los votos.
        uint256 currentVotes = proposals[idProposal]._votes_participant[msg.sender];
        uint256 votesAfterWithdraw = currentVotes - voteAmount;

        //Calcular tokens a devolver 
        uint256 tokensToReturn = (currentVotes*currentVotes)- (votesAfterWithdraw*votesAfterWithdraw);

        require(IERC20(address(votingContract)).balanceOf(address(this))>= tokensToReturn, "No tenemos suficientes tokens para retirarlos");

        //Lo tendremos que cambiar porque lo de Transfer limita el gas. 
        bool success = IERC20(address(votingContract)).transfer(msg.sender,tokensToReturn);
        require(success, "La transferencia de Tokens ha fallado"); 

        //Actualizamos el número de votos y tokens
        proposals[idProposal]._votes_participant[msg.sender] = votesAfterWithdraw;
        proposals[idProposal]._votes -= voteAmount;

    }


    function _checkAndExecuteProposal (uint256 idProposal) internal onlyAfterOpen {
        require(idProposal < numProposals, "La propuesta que estas pasando no existe");
        require(!proposals[idProposal]._isSignalign, "La propuesta debe ser de financiacion");
        require(!proposals[idProposal]._isCanceled, "La propuesta que quieres ejecutar ya ha sido cancelada");  
        require(!proposals[idProposal]._isApproved, "La propuesta sobre que quieres ejecutar ya ha sido aprobada"); 
        require(proposals[idProposal]._contractProposal != address(0), "La propuesta no tiene contrato de votacion asociado");
        require(totalBudget > proposals[idProposal]._budget, "El presupuesto total del contrato debe ser superior al demandado en la propuesta");

        proposals[idProposal]._isApproved = true;
        numPendingProposals--;

        //Convertir tokens a weis para convertirlos en presupuesto
        uint256 tokensValue = proposals[idProposal]._numTokens * votingContract.getTokenPrice();
        totalBudget += tokensValue;

        //Reducir el presupuesto con el presupuesto de la propuesta
        totalBudget -= proposals[idProposal]._budget;

        //Ejecutar la propuesta, tenemos que tener en cuenta el límite de gas. Tengo dudas de si se hace aquí o en un require.
        //Obviamente si tenemos que poner un límite concreto de gas IMPOSIBLE USAR TRANSFER.
        (bool success, )= proposals[idProposal]._contractProposal.call{value: proposals[idProposal]._budget, gas: 10000}
        (
            /*Tengo que usar lo de selector para poder llamar a executeProposal*/
            abi.encodeWithSelector(IExecutableProposal.executeProposal.selector,idProposal, proposals[idProposal]._votes, proposals[idProposal]._numTokens)
        );

        require(success, "La ejecucion de la propuesta ha fallado");
    }

    function closeVoting () external onlyOwner onlyAfterOpen{
        
        
        uint256[] memory pendingProposals= getPendingProposals();

        for (uint256 i=0; i < pendingProposals.length; i++) 
        {
            uint256 id = pendingProposals[i];
            proposals[id]._isCanceled=true;
            numPendingProposals--;

            //Tenemos que devolver tokens a los votantes   
        }

        isVotingOpen =false;
    }
    
}