// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


import "./ArrayUtils.sol";


interface ERC165 {
        function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}


 interface IERC721Receiver {
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
 }


interface ERC721simplified is ERC165 {
  // EVENTS
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);


  // APPROVAL FUNCTIONS
  function approve(address _approved, uint256 _tokenId) external payable;


  // TRANSFER FUNCTIONS
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;


  // VIEW FUNCTIONS (GETTERS)
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function getApproved(uint256 _tokenId) external view returns (address);
}






/*MUY IMPORTANTE QUITAR EL ASBTRACT MÁS TARDE PORQUE SI NO SE NOS RALLA.*/
contract MonsterTokens is ERC721simplified {


    struct Weapons {
        string[] names; // name of the weapon
        uint[] firePowers; // capacity of the weapon
    }
    struct Character {
        string name; // character name
        Weapons weapons; // weapons assigned to this character
        address tokenOwner;
    }


    uint public constant WEIS_NECESARIOS = 1000 wei;


    uint private tokenId=10000;
    mapping (uint => Character) public characters;
    mapping (uint => address) private approved; //Aquí almacenamos aquellos que esten aprobados para enviar
    mapping (address=> uint) private num_tokens;


    uint num_characters=0; //Numero de personajes que hays
    address private contractOwner;//Propietario del contrato (se necesita al final)


    constructor(){
        contractOwner=msg.sender;
    }


 


    /*Función payable porque el contrato recibe una cantidad de dinero del msg.sender pero no es necesario llamar a ningún payable.*/
    function createMonsterToken(string calldata character_name)external payable returns (uint) {
       
        require(msg.value == WEIS_NECESARIOS, "El importe a de ser mil weis");        
        tokenId++;




        Character memory c = Character(character_name,Weapons(new string[](0), new uint[](0)), msg.sender);
        characters[tokenId]= c;


        num_characters++;
        num_tokens[msg.sender]++;

        //Segun el estándar ERC 721, es obligatorio emitir el evento Transfer cuando creamos o destruimos tokens.
        emit Transfer(address(0), msg.sender, tokenId);
        return tokenId;
    }




    function removeMonsterToken(uint token) external {
       
        // require(token>10000 && token < 10000+ num_characters, "No hay ningun personaje");
        //He creado este require porque creo que es mejor comprobar si el tokenowner  es igual al msg.sender.
        require(characters[token].tokenOwner == msg.sender || msg.sender == approved[token] , "Solo el propietario y aprobado pueden ejecutar esta funcion");


        delete characters[token];


        num_characters--;
        num_tokens[characters[token].tokenOwner]--;//Eliminamos un token al token owner (independientemente de que sea un aprobado el que ejecuta la función porque no es suyo) 

        //En el caso de que haya alguien approved para dicho token, lo tenemos que eliminar.
        delete approved[token];

        payable(msg.sender).transfer(WEIS_NECESARIOS);

        //Segun el estándar ERC 721, es obligatorio emitir el evento Transfer cuando creamos o destruimos tokens.
        emit Transfer(msg.sender, address(0), token);
    }




    modifier weapon_notExist(uint character_tokenId, string calldata weapon_name){
        require(characters[character_tokenId].tokenOwner != address(0), "No puedes crear un arma a un personaje inexistente");
        require(!ArrayUtils.contains(characters[character_tokenId].weapons.names, weapon_name),"El arma que estas intentando crear ya existe");
        _;
    }


    function addWeapon(uint character_tokenId, string calldata weapon_name, uint fire_power) external payable weapon_notExist(character_tokenId, weapon_name){
       
        //Solo voy a permitir añadir por el momento al que sea el propietario, no permito a los aprobados por el propietario...
        Character storage c = characters[character_tokenId]; //Pillo al personaje con ese tokenID.
        require(c.tokenOwner == msg.sender || msg.sender == approved[character_tokenId], "Solo el propietario y aprobado pueden ejecutar esta funcion"); //Luego añadiremos para que también pueda cambiar las armas de los aprobados.

        //Tenemos que sacar el número de armas que tiene el token.
        uint num_weapons= c.weapons.names.length;
        uint cost = fire_power * (2 ** num_weapons);// al ejecutar esta funcion se debe proporcionar al menos la cantidad de firePower ∗ 2^i Weis
        //Al poner añadir me lo pone mal. No permite poner n's ni tildes en los mensajes de los require.
        require(msg.value >= cost, "No tienes suficientes weis para agregar el arma");


        //En el caso de que no se revierta nada de esto, le añadimos el arma y la potencia
        characters[character_tokenId].weapons.names.push(weapon_name);
        characters[character_tokenId].weapons.firePowers.push(fire_power);

        //No tenemos que pagar nada nosotros como contrato. El msg.sender pagará al contrato como mínimo lo que pone en el último require.
    }


    //Incrementa potencia de fuego de todas las armas de un personaje
    function incrementFirePower(uint character_tokenId, uint8 inc_per) external payable {


        Character storage c = characters[character_tokenId];


        //Ampliar más tarde a aquellas personas que estén aprobadas.
        require(c.tokenOwner == msg.sender||msg.sender == approved[character_tokenId], "Solo el propietario y aprobado pueden ejecutar esta funcion");//De momento, solo el propietario del token puede hacerlo


        uint cost = inc_per * inc_per; //Coste que tendrá aumentarle la potencia a las armas.


        require(msg.value >= cost, "No tienes suficientes weis para incrementar la potencia de tus armas");


        //Llamamos a la función arrayutils de la librería que hemos creado
        ArrayUtils.increment(c.weapons.firePowers, inc_per);
    }


    function collectProfits() external  {


        require(msg.sender == contractOwner, "Solo puedes recibir los profits de este contrato si eres el propietario del mismo");
        uint totalDeposits = num_characters *WEIS_NECESARIOS;//Numero de weis resultantes que tenemos que mantener
        uint profits = address(this).balance - totalDeposits; //Los beneficios que se llevaría.


        require(profits >0, "No hay beneficios para recoger");
        payable (contractOwner).transfer(profits); //Transferimos los beneficios al poseedor del contrato.
    }




    // APPROVAL FUNCTIONS
    function approve(address _approved, uint256 _tokenId) external payable  {
        require(msg.sender == characters[_tokenId].tokenOwner, "Emisor debe ser propietario del token");
        require(characters[_tokenId].tokenOwner != address(0), "Token no existe");


       
        uint cantidad = ArrayUtils.sum(characters[_tokenId].weapons.firePowers);


        require(msg.value >= cantidad, "Debes enviar al menos la suma de las potencias de fuego en Wei");


        approved[_tokenId] = _approved; //Guardamos el address de la dirección approved para ese tokenId.


        emit Approval(msg.sender, _approved, _tokenId);
    }


    // TRANSFER FUNCTIONS
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
        //Transferir la propiedad de un token a otro propietario.
        require(msg.sender == characters[_tokenId].tokenOwner || msg.sender == approved[_tokenId], "Emisor debe ser el poseedor del token o el que tiene aprobacion para hacer cosas con el token");
        require(characters[_tokenId].tokenOwner == _from, "No lo dice el enunciado, pero creo que el from es siempre el que posee el token, sin necesidad de que sea este el que ejecuta la operacion");


        uint cantidad = ArrayUtils.sum(characters[_tokenId].weapons.firePowers);
        require(msg.value>= cantidad, "Debes enviar al menos la suma de las potencias de fuego en Wei");


        //cambiamos el owner del token
        characters[_tokenId].tokenOwner = _to;
        num_tokens[_from]--;
        num_tokens[_to]++;


        //Como transferimos el token, ahora el que estaba aprobado no lo estará para el nuevo propietario
        delete approved[_tokenId];


        //Da igual que haya sido un approved el que haya intermediado la transferencia, envíamos al ex-poseedor del token y al acutal poseedor.
        emit Transfer(_from, _to, _tokenId);  
    }

    //Esta función hace lo mismo que la de arriba solo que de manera segura, puesto que checkea si le estamos enviando el token a un contrato, y en tal caso, chequea que el contrato pueda recibirlos.
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        require(msg.sender == characters[_tokenId].tokenOwner || msg.sender == approved[_tokenId], "Emisor debe ser el poseedor del token o el que tiene aprobacion para hacer cosas con el token");
        require(characters[_tokenId].tokenOwner == _from, "No lo dice el enunciado, pero creo que el from es siempre el que posee el token, sin necesidad de que sea este el que ejecuta la operacion");
       
        //retribución que recibe el contrato por soportar la función.
        uint cantidad = ArrayUtils.sum(characters[_tokenId].weapons.firePowers);
        require(msg.value>= cantidad, "Debes enviar al menos la suma de las potencias de fuego en Wei");


        if (_to.code.length > 0) { // Si _to es un contrato
            bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(retval == IERC721Receiver(_to).onERC721Received.selector, "Esto te comprueba si el contrato esta preparado para recibir nfts.");
        }


       //cambiamos el owner del token
        characters[_tokenId].tokenOwner = _to;
        num_tokens[_from]--;
        num_tokens[_to]++;


        //Como transferimos el token, ahora el que estaba aprobado no lo estará para el nuevo propietario
        delete approved[_tokenId];
       
        emit Transfer(_from, _to, _tokenId);
    }


    // VIEW FUNCTIONS (GETTERS)
    function balanceOf(address _owner) external view returns (uint256){
        require(_owner != address(0), "El usuario debe tener balance");
        return num_tokens[_owner];
    }


    function ownerOf(uint256 _tokenId) external view returns (address){
        require(characters[_tokenId].tokenOwner != address(0), "Token no existe");
       
        //Aquí me devuelvo el owner del token.
        return characters[_tokenId].tokenOwner;
    }
    function getApproved(uint256 _tokenId) external view returns (address){
        require(_tokenId>10000 && _tokenId <= 10000+ num_characters, "No hay ningun personaje");
         
        //Aquí me devuelvo el aprobado del token.
        return approved[_tokenId];
    }


    function supportsInterface(bytes4 interfaceID) external pure returns (bool){
        return interfaceID == type(ERC721simplified).interfaceId || interfaceID == type(ERC165).interfaceId ;
    }


}
