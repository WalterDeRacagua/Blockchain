//SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

contract DhondtElectionRegion {


    /*SECCIÓN DE VARIABLES*/
    mapping (uint => uint) private weights;
    uint regionId;
    uint[] results;


    /*CONSTRUCTOR*/
    constructor(uint num_partidos, uint region){
        regionId = region; //La region
        results = new uint[](num_partidos);
        savedRegionInfo();
    }


    /*MODIFICADORE*/
    modifier valid_party(uint party){
        require(party > 0 , "El id del partido tiene que ser mayor que 0");
        require(party <results.length, "El id del partido tiene que ser mayor que 0");
        _;
    }

    /*FUNCIONES*/
    function savedRegionInfo() private{
    weights[28] = 1; // Madrid
    weights[8] = 1; // Barcelona
    weights[41] = 1; // Sevilla
    weights[44] = 5; // Teruel
    weights[42] = 5; // Soria
    weights[49] = 4; // Zamora
    weights[9] = 4; // Burgos
    weights[29] = 2; // Malaga
    }


    function registerVote(uint voted_party) internal   returns  (bool){
       
        if(voted_party > 0 &&voted_party <results.length){
            results[voted_party] += weights[regionId];
            return true;
        }
        return false;


    }
}

abstract contract PollingStation{

    /*VARIABLES DE ESTADO*/
    bool public votingFinished;
    bool private votingOpen;
    address president;


    constructor(address presi){
        president = presi;
        votingFinished= false;
        votingOpen = false;
    }


    modifier isPresident(){
        require(president == msg.sender, "Esta funcion solo debe ejecutarla el presidente.");
        _;
    }
    modifier isOpened(){
        require(votingOpen ==true, "La mesa electoral debe estar abierta para poder cerrarla");
        _;
    }


    function openVoting()external isPresident{
        votingOpen=true;
    }


    function closeVoting() external isPresident isOpened{
        votingOpen = false;
        votingFinished = true;
    }


    function castVote(uint party_id) virtual external;
    function getResults() external virtual  view returns (uint [] memory);
}

contract DhondtPollingStation is DhondtElectionRegion, PollingStation{
    constructor(address president, uint num_partys, uint region_Id)
    PollingStation(president)
    DhondtElectionRegion(num_partys, region_Id) {}
   
    function castVote(uint party_id)  external override isOpened {
        registerVote(party_id);
    }


    function getResults() external view override returns (uint [] memory){


        require(votingFinished ==true, "La votacion no ha terminado aun. Espere a que termine.");


        return results;
    }
   
}


contract Election {

    /*VARIABLES DE ESTADO*/
    address authority; //Address de la autoridad    
    mapping (address => bool) private voters; //Direcciones de los votantes que han ejercido su derecho a voto
    mapping (uint => DhondtPollingStation) public pollingStations; // Mapeo de regionID a sedes electorales.
    uint num_parties;

    /*MODIFICADORES*/
    modifier onlyAuthority(){
        require(msg.sender == authority, "Solo la autoridad puede llegar a ejecutar esta funcion");
        _;
    }

    modifier freshId(uint regionId){
        require(address(pollingStations[regionId]) == address(0), "Ya existe una sede para esa region.");
        _;
    }

    modifier validId(uint regionId){
        require(address(pollingStations[regionId]) != address(0), "Debe existir una sede para esa region.");
        _;
    }

    constructor(uint n_parties){
        authority = msg.sender;
        num_parties = n_parties; //La cantidad de partidos electorales que hay en el sistema 
    }

    function createPollingStation(uint regionId, address president) external onlyAuthority freshId(regionId) returns (address){

        DhondtPollingStation newStation = new DhondtPollingStation(president, num_parties, regionId);
        pollingStations[regionId]= newStation;
        return address(newStation);
    }

    function castVote(uint regionId_voter, uint voted_party) external validId(regionId_voter){

        require(!voters[msg.sender], "El votante ya ha ejercido su derecho a voto.");

        voters[msg.sender]= true;

        //Registramos el voto en la sede correspondiente.
        pollingStations[regionId_voter].castVote(voted_party);
    } 

    function getResults() external onlyAuthority view returns (uint [] memory){
    //Inicializo una variable para almacenar los resultados
    uint[] memory results = new uint[](num_parties);

    for (uint i=0; i < num_parties; i++) 
    {
        results[i]=0;   
    }
    
    // Como no tenemos una lista explícita de regiones, esto es un ejemplo conceptual
    // En un caso real, deberías almacenar una lista de regionIds creados
    for (uint regionId = 0; regionId < 50; regionId++) { // Ejemplo con 50 regiones posibles
        if (address(pollingStations[regionId]) != address(0)) {
            // Comprobar si la votación ha terminado en esta sede
            require(pollingStations[regionId].votingFinished(), "Una o mas sedes no han terminado la votacion.");
            
            // Obtener los resultados de la sede
            uint[] memory regionResults = pollingStations[regionId].getResults();
            
            // Acumular los resultados
            for (uint i = 0; i < num_parties; i++) {
                results[i] += regionResults[i];
            }
        }
    }

    return results;
}

   
}
