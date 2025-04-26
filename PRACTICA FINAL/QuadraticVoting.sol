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

    mapping (uint256 => mapping (address => uint256)) proposal_votes_participant; //Número de votos por participante.


    /*PARTICIPANTES*/
    uint256  numParticipants;
    mapping (address=>bool)  participants;//Para ver si están registrados

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
        address _creator; //Creador de la propuesta
        
        bool _isSignaling; //Si no es de signalign será financiera
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

    /*Añadir un modificador que compruebe todo lo que se comprueban en las últimas funciones.*/




    /* FUNCIONES */
    
    /*DONE*/
    function openVoting () external payable onlyOwner {     
        require(!isVotingOpen, "La votacion ya esta abierta, no puedes volver a abrirla");
        require(msg.value >0, "El presupuesto inicial debe ser mayor que cero");

        //Presupuesto total inicial que servirá para aprobar las apuestas.
        totalBudget = msg.value;
        
        //Marcamos las votaciones como abiertas.
        isVotingOpen=true;
    }

    /*DONE*/
    function addParticipant () external payable{
        //Cuando se inscribe el participante debe transferir Ether para comprar Tokens (al menos uno).
        require(msg.value >= votingContract.getTokenPrice(), "No estas aportando suficiente Ether como para comprar tokens. Necesitas poder comprar 1 al menos.");
        require(!participants[msg.sender], "Participante ya esta registrado. No puedes registrarte otra vez");

        //Calculamos cuántos tokens podemos emitir con value aportado por el participante
        uint256 numTokens= msg.value/votingContract.getTokenPrice();
        require(numTokens>=1, "Necesitas poder comprar al menos un token");

        //Registrar participante
        participants[msg.sender]=true;
        numParticipants++;        

        //Minteamos los tokens
        votingContract.mint(msg.sender, numTokens);
    }

    /*DONE*/
    function removeParticipant() public {
        require(participants[msg.sender], "Particiapante no registrado. No puedes eliminar un participante que no esta registrado");

        //Eliminar participante
        participants[msg.sender]=false; //Desmarcamos del mapping a este participante.
        numParticipants--;        
    }

    /*DONE*/
    function addProposal (string calldata title, string calldata description, uint256 budget, address proposalContract) external onlyAfterOpen  returns (uint256) {
        require(participants[msg.sender], "Debes inscribirte como participante para poder crear una propuesta");
        require(proposalContract != address(0) , "La direccion del contrato no es valida");
        require(bytes(title).length >0 , "El titulo de la propuesta no puede ser vacio");
        require(bytes(description).length>0, "La descripcion de la propuesta no puede ser vacia");

        //Aumentamos el numero de propuestas y cogemos el índice actual para asignarselo a la nueva que queremos añadir.
        uint256 proposalId =numProposals;
        numProposals++;

        //Creamos el objeto propuesta asignando sus atributos correspondientes.
        Proposal storage newProposal=proposals[proposalId];
        newProposal.id = proposalId;
        newProposal._title = title;
        newProposal._description= description;
        newProposal._participants=0;
        newProposal._budget= budget; //Ahora estamos poniendo el presupuesto.
        newProposal._contractProposal= proposalContract;
        newProposal._creator=msg.sender;

        if (budget > 0)  {
            newProposal._isSignaling= false;

            /*Aumentamos el número de propuestas pendientes. Las propuestas pendientes solo pueden ser de financiacion*/
            numPendingProposals++;
        }
        else {

            //Las propuestas de signailig no tienen presupuesto
            newProposal._isSignaling= true ;
        }

        //De momento no hay ni votos ni tokens para la nueva propuesta.
        newProposal._votes=0;
        newProposal._numTokens=0; 

        //La propuesta no se ha cancelado ni aprobado por el momento, la acabamos de crear
        newProposal._isApproved=false;
        newProposal._isCanceled=false;

        //Tenemos que meter dentro del array todas las propuestas, luego en los getters comprobamos el resto de cosas.
        proposalsArray.push(proposalId);    

        return proposalId;
    }
    
    //TODO, falta devolver tokens
    function cancelProposal (uint idProposal) public onlyAfterOpen {
        require(idProposal < numProposals, "No existe esa propuesta");
        require(msg.sender == proposals[idProposal]._creator, "No puedes cancelar la propuesta si no eres el creador de la misma");
        require(!proposals[idProposal]._isApproved, "No se pueden cancelar propuestas ya aprobadas.");
        require(!proposals[idProposal]._isCanceled, "No se puede cancelar si la propuesta ya ha sido cancelada anteriormente");

        //Cancelamos la propuesta
        proposals[idProposal]._isCanceled=true;

        //Si es de financiación...
        if (!proposals[idProposal]._isSignaling){ 
            numPendingProposals--;
        }

        /*NO TENEMOS QUE QUITAR DEL ARRAY PORQUE NO SE PUEDE HACER UN POP COMO EN JAVA */

        /*FALTA DEVOLVER LOS TOKENS COMPRADOS.*/
    }

    /*DONE*/
    function buyTokens() external payable {
        require(participants[msg.sender], "Para comprar tokens necesitas haberte inscrito como participante");
        require(msg.value >= votingContract.getTokenPrice(), "Debes enviar el Ether necesario para poder comprar al menos un token.");

        //Comprobamos cuántos tokens podría comprar con el value aportado 
        uint256 boughtTokens = msg.value/ votingContract.getTokenPrice();

        //No se si esta comprobación es necesaria.
        require(boughtTokens >= 1, "Necesitas comprar al menos un Token");

        
        /*
        PARA RECORDARLO YO: El término "mintear" proviene del inglés "mint", que significa "acuñar" o "crear"
        en el contexto de monedas o activos. Mintea ese número de tokens
        */
        votingContract.mint(msg.sender, boughtTokens);
    }

    /*DONE*/
    function sellTokens (uint256 tokensToReturn)  external  {
        require(participants[msg.sender], "Para vender tokens necesitas haberte inscrito como participante");
        require(tokensToReturn > 0, "No puedes vender una cantidad inferior a 1 token.");
        require(votingContract.balanceOf(msg.sender)>= tokensToReturn, "No puedes vender mas tokens de los que posees");

        uint256 refund = tokensToReturn * votingContract.getTokenPrice();
        require(address(this).balance >= refund, "El contrato no tiene recursos para devolverte el Ether.");

        votingContract.burn(msg.sender, tokensToReturn); //Los borramos de la cuenta del contrato para no estar volviendo

        (bool success, )= msg.sender.call{value: refund}("");
        require(success, "La transferencia de Ether al participante ha fallado.");
    }

    /*DONE*/
    function getERC20() external view returns (address) {

        return address(votingContract);
    }

    /*DONE*/
    function getPendingProposals() internal view onlyAfterOpen returns (uint[] memory ){

        uint256[] memory tempIDs = new uint256[](proposalsArray.length);//Queremos un array mínimamente del tamaño de las peticiones pendientes
        uint256 numPending=0;
        //Ese tamaño no es el tamaño real que queremos, tenemos que meter los elementos que queramos y después volver a meterlos en otro array que tenga el tamaño real

        /*ESTOS FORS QUIZÁS PODEMOS REDUCIR LA CANTIDAD DE GAS CON YUL*/
        for (uint256 i=0; i< proposalsArray.length; i++) 
        {
            uint256 p_id= proposalsArray[i];//Sacamos el id

            //Tenemos que comprobar que sea de financiación y que además no haya sido aprobada NI cancelada
            if (!proposals[p_id]._isSignaling && !proposals[p_id]._isApproved && !proposals[p_id]._isCanceled) {
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

    /*DONE*/
    function getApprovedProposals() internal view onlyAfterOpen returns (uint[] memory ){
        
        uint256[] memory tempIDs = new uint256[](proposalsArray.length);//Queremos un array mínimamente del tamaño de las peticiones pendientes
        uint256 numPending=0;
        //Ese tamaño no es el tamaño real que queremos, tenemos que meter los elementos que queramos y después volver a meterlos en otro array que tenga el tamaño real

        /*ESTOS FORS QUIZÁS PODEMOS REDUCIR LA CANTIDAD DE GAS CON YUL*/
        for (uint256 i=0; i< proposalsArray.length; i++) 
        {
            uint256 p_id= proposalsArray[i];//Sacamos el id

            //Tenemos que comprobar que sea de financiación y que además haya sido aprobada 
            if (!proposals[p_id]._isSignaling && proposals[p_id]._isApproved) {
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

    /*DONE*/
    function getSignalingProposals() internal view onlyAfterOpen returns (uint[] memory){
        
        uint256[] memory tempIDs = new uint256[](proposalsArray.length);//Queremos un array mínimamente del tamaño de las peticiones pendientes
        uint256 numPending=0;
        //Ese tamaño no es el tamaño real que queremos, tenemos que meter los elementos que queramos y después volver a meterlos en otro array que tenga el tamaño real

        /*ESTOS FORS QUIZÁS PODEMOS REDUCIR LA CANTIDAD DE GAS CON YUL*/
        for (uint256 i=0; i< proposalsArray.length; i++) 
        {
            uint256 p_id= proposalsArray[i];//Sacamos el id

            //Tenemos que comprobar que sea de signalign 
            if (proposals[p_id]._isSignaling) {
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

    /*DONE*/
    function getProposalInfo (uint256 idProposal) external view onlyAfterOpen returns (Proposal memory){
        require(idProposal < numProposals, "No existe esa propuesta");
        
        //Propuesta que vamos a devolver.
        Proposal memory p_info;
        
        /*Asignamos todo menos las votaciones*/
        p_info.id = idProposal;
        p_info._budget= proposals[idProposal]._budget;
        p_info._contractProposal=  proposals[idProposal]._contractProposal;
        p_info._creator =  proposals[idProposal]._creator;
        p_info._description =  proposals[idProposal]._description;
        p_info._isApproved =  proposals[idProposal]._isApproved;
        p_info._isCanceled =  proposals[idProposal]._isCanceled;
        p_info._isSignaling =  proposals[idProposal]._isSignaling;
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

        uint256 currentVotes= proposal_votes_participant[idProposal][msg.sender];
        uint256 totalVotes= currentVotes + voteAmount;//Votos totales que tendra el participante.

        //¿Cuántos tokens necesitará?
        uint256 tokensNeeded = (totalVotes*totalVotes)-(currentVotes*currentVotes);

        require(IERC20(address(votingContract)).allowance(msg.sender,address(this))>= tokensNeeded, "No tienes suficientes tokens para votar");

        bool success = IERC20(address(votingContract)).transferFrom(msg.sender, address(this), tokensNeeded);
        require(success, "La transferencia de Tokens ha fallado");


        //Si se trata de un votante nuevo lo tenemos que meter en el array
        if (currentVotes==0){
            proposals[idProposal]._voters.push(msg.sender);
        }

        //Actualizamos los votos y tokens si ha ido todo guay
        proposal_votes_participant[idProposal][msg.sender]= totalVotes ; 
        proposals[idProposal]._votes+= voteAmount;
        proposals[idProposal]._numTokens += tokensNeeded;
    }
    
    function withdrawFromProposal (uint256 voteAmount, uint256 idProposal) external onlyAfterOpen {
        require(idProposal < numProposals, "La propuesta que estas pasando no existe");
        require(participants[msg.sender], "Debes darte de alta como participante para ejecutar esta funcion");
        require(voteAmount >0, "Necesitas dejar un voto por lo menos."); 
        require(!proposals[idProposal]._isCanceled, "La propuesta sobre la que quieres retirar votos ya ha sido cancelada");
        require(!proposals[idProposal]._isApproved, "La propuesta ya ha sido aprobada");
        require(proposal_votes_participant[idProposal][msg.sender] >= voteAmount, "Estas intentando retirar mas votos de los que has realizado" );       

        //Calcular cuántos votos tenemos ahora, y con cuantos nos vamos a quedar tras retirar los votos.
        uint256 currentVotes = proposal_votes_participant[idProposal][msg.sender];
        uint256 votesAfterWithdraw = currentVotes - voteAmount;

        //Calcular tokens a devolver 
        uint256 tokensToReturn = (currentVotes*currentVotes)- (votesAfterWithdraw*votesAfterWithdraw);

        require(IERC20(address(votingContract)).balanceOf(address(this))>= tokensToReturn, "No tenemos suficientes tokens para retirarlos");

        //Lo tendremos que cambiar porque lo de Transfer limita el gas. 
        bool success = IERC20(address(votingContract)).transfer(msg.sender,tokensToReturn);
        require(success, "La transferencia de Tokens ha fallado"); 

        //Actualizamos el número de votos y tokens
        proposal_votes_participant[idProposal][msg.sender] = votesAfterWithdraw;
        proposals[idProposal]._votes -= voteAmount;
        proposals[idProposal]._numTokens -= tokensToReturn;

        //Ahora tenemos que actualizar el array por si el número de votos es 0.
        //Seguro que hay una forma algo más eficiente de hacer esto... Preguntar
        if (votesAfterWithdraw ==0) {
            //recorremos los votos. En el peor de los casos es lineal 
            for (uint256 i=0; i< proposals[idProposal]._voters.length; i++) 
            {
                if ( proposals[idProposal]._voters[i]==msg.sender) {
                    //Lo que voy a hacer (no se si está bien) es cambiar de posición al último el que quiero eliminar para hacer el pop() correctamente
                    proposals[idProposal]._voters[i] = proposals[idProposal]._voters[proposals[idProposal]._voters.length-1];
                    proposals[idProposal]._voters.pop();

                    /*
                    Lo que he querido hacer es cambiar por el último el que quiero quitar, de forma que en la posición
                    i actual tenemos el que antes era el último. En la última posición tenemos el mismo que en i ahora
                    mismo (duplicado), por lo que eliminamos el último con pop().
                    */

                    //No se si esto te saca del bucle en Solidity, supongo que si.
                    break ; 
                }
            }
        }


    }


    function _checkAndExecuteProposal (uint256 idProposal) internal onlyAfterOpen {
        require(idProposal < numProposals, "La propuesta que estas pasando no existe");
        require(!proposals[idProposal]._isSignaling, "La propuesta debe ser de financiacion");
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

        /*Coste (p*v) con p siendo el numero de propuestas de financiación y v los votantes de esa propuesta*/
        for (uint256 i=0; i < pendingProposals.length; i++) 
        {
            uint256 id = pendingProposals[i];
            proposals[id]._isCanceled=true;
            numPendingProposals--;

            //Tenemos que devolver tokens a los votantes 
            for (uint256 j = 0; j < proposals[id]._voters.length; j++) {
                
                address voter = proposals[id]._voters[j];
                uint256 numVotesVoter = proposal_votes_participant[id][voter];

                if (numVotesVoter>0) {
                    uint256 tokensToReturn = numVotesVoter * numVotesVoter;
                    proposal_votes_participant[id][voter]=0;

                    if (tokensToReturn >0) {

                        /*IMPORTANTE, NO SE HACE CON TRANSFER PORQUE LIMITA EL GAS, CAMBIAR POR CALL.*/
                        IERC20(address(votingContract)).transfer(voter, tokensToReturn);
                        //Continuar incluso si falla para no bloquear.
                    }
                }

            }

            //Ya no tiene votos la propuesta
            proposals[id]._votes =0;
            proposals[id]._numTokens =0;
            proposals[id]._voters = new address[](0);

        }

        uint256[] memory signalignProposalsResult= getSignalingProposals();
          // Procesar propuestas de signaling (ejecutar y devolver tokens)
        for (uint256 i = 0; i < signalignProposalsResult.length; i++) {
            uint256 proposalId = signalignProposalsResult[i];
            Proposal storage proposal = proposals[proposalId];

            if (!proposal._isCanceled && !proposal._isApproved) {
                // Ejecutar propuesta de signaling
                if (proposal._contractProposal != address(0)) {
                    proposal._contractProposal.call{value: 0}
                    (
                        abi.encodeWithSelector(
                            IExecutableProposal.executeProposal.selector,
                            proposalId,
                            proposal._votes,
                            proposal._numTokens
                        )
                    );
                    // Continuar incluso si falla
                }

                // Devolver tokens a los votantes
                for (uint256 j = 0; j < proposal._voters.length; j++) {
                    address voter = proposal._voters[j];
                    uint256 votes =  proposal_votes_participant[proposalId][voter];
                    if (votes > 0) {
                        uint256 tokensToReturn = votes * votes;
                        proposal_votes_participant[proposalId][voter]= 0;
                        if (tokensToReturn > 0) {
                            //Esto tendremos que cambiarlo
                            IERC20(address(votingContract)).transfer(voter, tokensToReturn);
                        }
                    }
                }
                proposal._votes = 0;
                proposal._numTokens = 0;
                proposal._voters = new address[](0);
            }
        }

        // Transferir presupuesto no gastado al propietario
        if (totalBudget > 0) {
            uint256 budgetToTransfer = totalBudget;
            totalBudget = 0;
            payable(_owner).transfer(budgetToTransfer);
        }

        // Reiniciar estado para nuevo proceso de votación
        isVotingOpen = false;
        proposalsArray = new uint256[](0);
        numProposals = 0;
        numPendingProposals = 0;
    }
    
}