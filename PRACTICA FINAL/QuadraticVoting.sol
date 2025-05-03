// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Librería ERC20 de OpenZeppelin 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "./VotingContract.sol";
import "./ExecutableProposal.sol";

contract QuadraticVoting{ 
    VotingContract  votingContract; 
    uint256 totalBudget; 
    address  immutable _owner; //Owner del contrato. Es el que crea el contrato y será siempre el que crea el contrato
    bool isVotingOpen; //Almacenamos si la votación está abierta.
    mapping (uint256 => mapping (address => uint256)) proposal_votes_participant; //Número de votos por participante en una propuesta
    mapping (uint256 => mapping (address => uint256)) proposal_participant_index; //Indice en el array del votante correspondiente para esa propuesta.
    mapping (uint256 => mapping (address => bool)) proposal_participant_hasVoted; //Rastrea si un usuario ha votado en una propuesta.
    mapping (uint256 => uint256) proposal_indexInPending; //Para cada propuesta (id) cuál es su indice en el array de pending.
    mapping (uint256 => uint256) proposal_indexInSignalign; //Para cada propuesta (id) de signaling, cuál es su  indice en el array de pending.

    uint256  numParticipants;
    mapping (address=>bool)  participants;//Para ver si están registrados

    struct Proposal {
        uint256 id;
        string _title; 
        string _description;
        uint256 _budget;
        uint256 _votes; 
        uint256 _umbral;
        address _contractProposal; //Será el receptor del dinero presupuestado en caso de ser aprobada la propuesta.
        address _creator; 
        bool _isSignaling; 
        bool _isApproved;
        bool _isCanceled;
        uint256 _numTokens; //Número total de tokens que hay en la propuesta
        address[] _voters;//Necesitamos añadir un array con los addresses de los votantes para recorrerlos en la función de closeVoting
    }
    mapping (uint => Proposal) proposals;//Id de la propuesta-> propuesta
    uint256 numProposals; //Numero de propuestas

    /*Arrays para reducir el coste de los getters*/
    uint256[] pendingProposals; //Propuestas pending para evitar tener que hacer bucles en getters. Guardamos los ids.
    uint256[] approvedProposals;
    uint256[] signalingProposals; //Propuestas de signaling para evitar tener que hacer bucles en getters. Guardamos los ids.

    //constructor de quadratic voting.
    constructor(uint256 _tokenPrice, uint256 _maxTokens) {
        require(_tokenPrice >0, "Precio tokens ha de ser>0");
        require(_maxTokens>0, "Tokens > cero");
        _owner = msg.sender; 
        isVotingOpen = false;
        votingContract = new VotingContract("DAO", "DVT", _tokenPrice, _maxTokens);
    }

    /*EVENTOS*/
    event VotingOpen();
    event VotingClosed();
    event NewProposal(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event ProposalApproved(uint256 indexed proposalId);

    /* MODIFICADORES */
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Debes ser el owner");_;
    }
    modifier onlyAfterOpen() {
        require(isVotingOpen, "La votacion tiene que estar abierta");_;
    }
    modifier onlyProposalExist(uint256 idProposal){
        require(idProposal < numProposals, "La propuesta no existe");_;
    }
    modifier onlyExistentParticipants(){
        require(participants[msg.sender], "Debes haberte inscrito");_;
    }
    modifier onlyNotCanceled(uint256 idProposal){
        require(!proposals[idProposal]._isCanceled, "propuesta ya cancelada"); _;
    }
    modifier onlyNotApproved(uint256 idProposal){
        require(!proposals[idProposal]._isApproved, "La propuesta ya ha sido aprobada");_; 
    }

    /*FUNCIONES AUXILIARES*/
    function calculateThresold(uint256 idProposal) internal view returns (uint256) {
        if (totalBudget==0) {
            return type(uint256).max;
        }
        // Proposal storage p = proposals[idProposal];
        uint256 firstPart = (2e17 + (proposals[idProposal]._budget*1e18/totalBudget)) * numParticipants/1e18;
        return firstPart + pendingProposals.length;       
    }

    function transferTokens(address to, uint256 amount) internal {
        require(amount >0, "Cantidad > 0");
        require(to != address(0), "El address debe existir");
        (bool success, ) = address(votingContract).call{gas:100000}(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        require(success, "La transferencia de tokens ha fallado.");
    }

    function removeFromArrayAndMapping(uint256[] storage array, mapping(uint256=>uint256) storage map, uint256 idProposal)internal{
        uint256 index = map[idProposal];
        uint256 last = array.length-1;
        if (index != last) {
            uint256 lastProposalId = array[last];
            array[index]= lastProposalId;
            map[lastProposalId]=index;
        }
        array.pop();
        delete map[idProposal];
    }

    /* FUNCIONES QUE SE PIDEN EN EL ENUNCIADO*/
    
    /*DONE*/
    function openVoting () external payable onlyOwner {     
        require(!isVotingOpen, "No puedes volver a abrirla");
        require(msg.value >0, "Presup init > cero");
        totalBudget = msg.value;
        isVotingOpen=true;
        emit VotingOpen();
    }

    /*DONE*/
    function addParticipant () external payable{
        //Cuando se inscribe el participante debe transferir Ether para comprar Tokens (al menos uno).
        require(msg.value >= votingContract.getTokenPrice(), "No aportas suficiente Ether");
        require(!participants[msg.sender], "Participante ya esta activo");

        //Calculamos cuántos tokens podemos emitir con value aportado por el participante
        uint256 numTokens= msg.value/votingContract.getTokenPrice();
        require(numTokens>=1, "Necesitas comprar un token min");
        //Registrar participante
        participants[msg.sender]=true;
        numParticipants++;        
        //Minteamos los tokens
        votingContract.mint(msg.sender, numTokens);
    }

    /*DONE*/
    function removeParticipant() public onlyExistentParticipants {
        participants[msg.sender]=false; //Desmarcamos del mapping a este participante.
        numParticipants--;        
    }

    /*DONE*/
    function addProposal (string calldata title, string calldata description, uint256 budget, address proposalContract) external onlyAfterOpen onlyExistentParticipants  returns (uint256) {
        require(proposalContract != address(0) , "Dir contrato no valida");
        require(bytes(title).length >0 , "Titulo no vacio");
        require(bytes(description).length>0, "La descripcion vacia");

        //Aumentamos el numero de propuestas y cogemos el índice actual para asignarselo a la nueva que queremos añadir.
        uint256 proposalId =numProposals;
        numProposals++;
        //Creamos el objeto propuesta asignando sus atributos correspondientes. Variable storage locales actúan como punteros.
        Proposal storage newProposal=proposals[proposalId];
        newProposal.id = proposalId;
        newProposal._title = title;
        newProposal._description= description;
        newProposal._budget= budget; //Ahora estamos poniendo el presupuesto.
        newProposal._contractProposal= proposalContract;
        newProposal._creator=msg.sender;
        if (budget > 0)  {
            newProposal._isSignaling= false;
            pendingProposals.push(proposalId);
            proposal_indexInPending[proposalId]= pendingProposals.length -1;
            newProposal._umbral = calculateThresold(proposalId);
        }
        else {
            newProposal._isSignaling= true;
            signalingProposals.push(proposalId);
            proposal_indexInSignalign[proposalId]= signalingProposals.length-1;
        }

        //De momento no hay ni votos ni tokens para la nueva propuesta.
        newProposal._votes=0;
        newProposal._numTokens=0; 
        //La propuesta no se ha cancelado ni aprobado por el momento, la acabamos de crear
        newProposal._isApproved=false;
        newProposal._isCanceled=false;

        emit NewProposal(proposalId);
        return proposalId;
    }
    
    /*Si no me equivoco, como hay que devolver a cada votante sus tokens, este método tiene que ser lineal*/
    function cancelProposal (uint idProposal) public onlyAfterOpen onlyProposalExist(idProposal) onlyNotCanceled(idProposal)
    onlyNotApproved(idProposal){
        require(msg.sender == proposals[idProposal]._creator, "Debes haber creado la propuesta");
        //Cancelamos la propuesta
        proposals[idProposal]._isCanceled=true;

        //Si es de financiación entonces 
        if (!proposals[idProposal]._isSignaling){ 
            removeFromArrayAndMapping(pendingProposals, proposal_indexInPending, idProposal);
        }
        else{
            removeFromArrayAndMapping(signalingProposals, proposal_indexInSignalign, idProposal);
        }

        for (uint256 i=0; i <proposals[idProposal]._voters.length; i++) 
        {
            address voter = proposals[idProposal]._voters[i];
            uint256 votes = proposal_votes_participant[idProposal][voter];
            if (votes >0) {
                uint256 tokensReturn = votes*votes;
                if (tokensReturn >0) {
                    transferTokens(voter,tokensReturn);
                }
            }   
            delete proposal_votes_participant[idProposal][voter];
            delete proposal_participant_index[idProposal][voter];
            delete proposal_participant_hasVoted[idProposal][voter];
        }

        proposals[idProposal]._votes=0;
        proposals[idProposal]._numTokens=0;
        delete proposals[idProposal]._voters;
        emit ProposalCanceled(idProposal);
    }

    /*DONE*/
    function buyTokens() external payable onlyExistentParticipants {
        require(msg.value >= votingContract.getTokenPrice(), "Debes enviar el Ether necesario");
        //Comprobamos cuántos tokens podría comprar con el value aportado 
        uint256 boughtTokens = msg.value/ votingContract.getTokenPrice();

        votingContract.mint(msg.sender, boughtTokens);
    }

    /*DONE*/
    function sellTokens (uint256 tokensToReturn)  external onlyExistentParticipants {
        require(tokensToReturn > 0, "cantidad inferior a 1");
        require(votingContract.balanceOf(msg.sender)>= tokensToReturn, "No tienes tokens suficientes");

        uint256 refund = tokensToReturn * votingContract.getTokenPrice();
        require(address(this).balance >= refund, "El contrato no tiene recursos");

        votingContract.burn(msg.sender, tokensToReturn); //Los borramos de la cuenta del contrato para no estar volviendo

        (bool success, )= msg.sender.call{value: refund}("");
        require(success, "La transferencia fallo");
    }

    /*DONE*/
    function getERC20() external view returns (address) {

        return address(votingContract);
    }

    /*DONE*/
    function getPendingProposals() external  view onlyAfterOpen returns (uint[] memory ){
        return pendingProposals;
    }

    /*DONE*/
    function getApprovedProposals() external view onlyAfterOpen returns (uint[] memory ){
        return approvedProposals;
    }

    /*DONE*/
    function getSignalingProposals() external  view onlyAfterOpen returns (uint[] memory){
        return signalingProposals;
    }

    /*DONE*/
    function getProposalInfo (uint256 idProposal) external view onlyAfterOpen onlyProposalExist(idProposal) returns (Proposal memory){
        return proposals[idProposal];
    }

    /*NO DICE NADA PERO YO SUPONGO QUE HAY QUE LLAMAR SOLO SI LA VOTACIÓN ESTÁ ABIERTA.*/
    function stake (uint256 idProposal, uint256 voteAmount) external onlyAfterOpen onlyProposalExist(idProposal) onlyExistentParticipants  
    onlyNotCanceled(idProposal) onlyNotApproved(idProposal){
        require(voteAmount >0, "No depositar menos 1 voto");
        
        /*
        Una vez estas comprobaciones, vamos a ver cuántos votos ha hecho ya el participante para comprobar los tokens
        que necesita para realizar la propuesta. 
        */
        uint256 currentVotes= proposal_votes_participant[idProposal][msg.sender];
        uint256 totalVotes= currentVotes + voteAmount;//Votos totales que tendra el participante.

        //¿Cuántos tokens necesitará?
        uint256 tokensNeeded = (totalVotes*totalVotes)-(currentVotes*currentVotes);

        require(IERC20(address(votingContract)).allowance(msg.sender,address(this))>= tokensNeeded, "No tienes suficientes tokens");

        bool success = IERC20(address(votingContract)).transferFrom(msg.sender, address(this), tokensNeeded);
        require(success, "La transferencia fallo");

        //Si se trata de un votante nuevo lo tenemos que meter en el array de votos
        if (currentVotes==0){
            proposals[idProposal]._voters.push(msg.sender);
            proposal_participant_index[idProposal][msg.sender]= proposals[idProposal]._voters.length - 1;
            proposal_participant_hasVoted[idProposal][msg.sender]= true;
        }

        //Actualizamos los votos y tokens si ha ido todo guay
        proposal_votes_participant[idProposal][msg.sender]= totalVotes ; 
        proposals[idProposal]._votes+= voteAmount;
        proposals[idProposal]._numTokens += tokensNeeded;

        /*Como hemos recibido un voto, tenemos que recalcular el umbral*/
        if (!proposals[idProposal]._isSignaling){
            //Llamar a un método que nos recalcule el umbral (llamando a una función interna).
            proposals[idProposal]._umbral;

            if (proposals[idProposal]._votes > proposals[idProposal]._umbral && totalBudget >= proposals[idProposal]._budget) {
                _checkAndExecuteProposal(idProposal);
            }
        }
    }
    
    /*Intentar buscar un mapping y arrays para reducir el coste del bucle for.*/
    function withdrawFromProposal (uint256 voteAmount, uint256 idProposal) external onlyAfterOpen onlyProposalExist(idProposal) 
    onlyExistentParticipants  onlyNotCanceled(idProposal) onlyNotApproved(idProposal){
        require(voteAmount >0, "Necesitas un voto al menos."); 
        require(proposal_votes_participant[idProposal][msg.sender] >= voteAmount, "Estas intentando retirar mas votos" );       
        //Calcular cuántos votos tenemos ahora, y con cuantos nos vamos a quedar tras retirar los votos.
        uint256 currentVotes = proposal_votes_participant[idProposal][msg.sender];
        uint256 votesAfterWithdraw = currentVotes - voteAmount;
        //Calcular tokens a devolver 
        uint256 tokensToReturn = (currentVotes*currentVotes)- (votesAfterWithdraw*votesAfterWithdraw);
        require(IERC20(address(votingContract)).balanceOf(address(this))>= tokensToReturn, "No se puede retirar");

        transferTokens(msg.sender, tokensToReturn);
        //Actualizamos el número de votos y tokens
        proposal_votes_participant[idProposal][msg.sender] = votesAfterWithdraw;
        proposals[idProposal]._votes -= voteAmount;
        proposals[idProposal]._numTokens -= tokensToReturn;

        //Ahora tenemos que actualizar el array por si el número de votos es 0.
        if (votesAfterWithdraw ==0) {
            uint256 index =proposal_participant_index[idProposal][msg.sender];
            uint256 last = proposals[idProposal]._voters.length-1;
            if (index != last) {
                /*Tendremos que cambiar posición y después popear*/
                address lastVoter = proposals[idProposal]._voters[last];
                proposals[idProposal]._voters[index]= lastVoter;
                proposal_participant_index[idProposal][lastVoter]=index;
            }

            proposals[idProposal]._voters.pop();
            proposal_participant_hasVoted[idProposal][msg.sender]= false; //Ya no ha votado en la propuesta
            delete proposal_participant_index[idProposal][msg.sender];
        }
    }

    function _checkAndExecuteProposal (uint256 idProposal) internal onlyAfterOpen onlyProposalExist(idProposal) onlyNotCanceled(idProposal)
    onlyNotApproved(idProposal){
        require(!proposals[idProposal]._isSignaling, "La propuesta  financiacion");
        require(proposals[idProposal]._contractProposal != address(0), "La propuesta sin contrato de votacion asociado");
        require(totalBudget > proposals[idProposal]._budget, "presupuesto debe ser > al demandado en la propuesta");

        proposals[idProposal]._isApproved = true;
        removeFromArrayAndMapping(pendingProposals, proposal_indexInPending, idProposal);       
        approvedProposals.push(idProposal); //Aumentamos el número de propuestas
        //Convertir tokens a weis para convertirlos en presupuesto
        uint256 tokensValue = proposals[idProposal]._numTokens * votingContract.getTokenPrice();
        totalBudget += tokensValue;

        //Reducir el presupuesto con el presupuesto de la propuesta
        totalBudget -= proposals[idProposal]._budget;


        (bool success, )= proposals[idProposal]._contractProposal.call{value: proposals[idProposal]._budget, gas: 100000}
        (
            /*Tengo que usar lo de selector para poder llamar a executeProposal*/
            abi.encodeWithSelector(IExecutableProposal.executeProposal.selector,idProposal, proposals[idProposal]._votes, proposals[idProposal]._numTokens)
        );
        require(success, "La ejecucion ha fallado");
        emit ProposalApproved(idProposal);
    }

    function closeVoting () external onlyOwner onlyAfterOpen{       

        /*Coste (p*v) con p siendo el numero de propuestas de financiación y v los votantes de esa propuesta*/
        for (uint256 i=0; i < pendingProposals.length; i++) 
        {
            uint256 id = pendingProposals[i];
            proposals[id]._isCanceled=true;

            //Tenemos que devolver tokens a los votantes 
            for (uint256 j = 0; j < proposals[id]._voters.length; j++) {  
                address voter = proposals[id]._voters[j];
                uint256 numVotesVoter = proposal_votes_participant[id][voter];
                if (numVotesVoter>0) {
                    uint256 tokensToReturn = numVotesVoter * numVotesVoter;
                    proposal_votes_participant[id][voter]=0;
                    proposal_participant_hasVoted[id][voter]= false;
                    if (tokensToReturn >0) {
                        transferTokens(voter, tokensToReturn);
                    }
                }
                delete proposal_votes_participant[id][voter];
                delete proposal_participant_index[id][voter];
                delete proposal_participant_hasVoted[id][voter];
                delete  proposal_indexInPending[id];
            }

            //Ya no tiene votos la propuesta
            proposals[id]._votes =0;
            proposals[id]._numTokens =0;
            delete proposals[id]._voters;
        }

          // Procesar propuestas de signaling (ejecutar y devolver tokens)
        for (uint256 i = 0; i < signalingProposals.length; i++) {
            uint256 proposalId = signalingProposals[i];
            Proposal storage proposal = proposals[proposalId]; //Como un puntero de Java, como nos dijo Jesús.
            if (!proposal._isCanceled && !proposal._isApproved) {
                // Ejecutar propuesta de signaling
                if (proposal._contractProposal != address(0)) {
                    (bool success, ) =proposal._contractProposal.call{value: 0, gas:100000}
                    (
                        abi.encodeWithSelector(
                            IExecutableProposal.executeProposal.selector,
                            proposalId,
                            proposal._votes,
                            proposal._numTokens
                        )
                    );
                    // He decidido que si no hay éxito (!success) no revertir, pero para eliminar warning hago el siguiente codigo 
                    if (!success) {
                        
                    }
                }

                // Devolver tokens a los votantes
                for (uint256 j = 0; j < proposal._voters.length; j++) {
                    address voter = proposal._voters[j];
                    uint256 votes =  proposal_votes_participant[proposalId][voter];
                    if (votes > 0) {
                        uint256 tokensToReturn = votes * votes;
                        proposal_votes_participant[proposalId][voter]= 0;
                        proposal_participant_hasVoted[proposalId][voter]= false;
                        if (tokensToReturn > 0) {
                            transferTokens(voter, tokensToReturn);
                        }
                    }
                    delete proposal_votes_participant[proposalId][voter];
                    delete proposal_participant_index[proposalId][voter];
                    delete proposal_participant_hasVoted[proposalId][voter];
                }
                proposal._votes = 0;
                proposal._numTokens = 0;
                delete proposals[proposalId]._voters;
                delete proposal_indexInSignalign[proposalId];
            }
        }

        // Transferir presupuesto no gastado al propietario
        if (totalBudget > 0) {
            uint256 budgetToTransfer = totalBudget;
            totalBudget = 0;
            (bool success, ) =_owner.call{value: budgetToTransfer}("");
            require(success, "transferencia  ha fallado.");
        }

        // Reiniciar estado para nuevo proceso de votación
        isVotingOpen = false;
        signalingProposals = new uint256[](0);
        pendingProposals= new uint256[](0);
        approvedProposals =new uint256[](0);
        numProposals = 0;

        /*AÑADIR UN EVENTO QUIZÁS PARA QUE DESDE FUERA PUEDAN SABER QUE SE HA CERRADO LA VOTACIÓN*/
        emit VotingClosed();
    }
}