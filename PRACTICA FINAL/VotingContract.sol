// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//Librería ERC20 de OpenZeppelin 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract VotingContract is ERC20{

    uint256 public immutable tokenPrice; //Constante que almacena el precio por token en Wei de los tokens vendidos
    uint256 public immutable maxTokens; //Constante que almacena el número máximo de tokens a vender.
    uint256 public mintedTokens;//Estos son los tokens que se han emitido 
    address public _owner;

    constructor(string memory name, string memory symbol, uint256 _tokenPrice, uint256 _maxTokens)ERC20(name,symbol){
        require(_tokenPrice >0, "El precio no puede ser menor que cero");
        require(_maxTokens >0 ,"El maximo de tokens no puede ser menor que cero");
        tokenPrice=_tokenPrice;
        maxTokens=_maxTokens; 
        mintedTokens=0;
    }

    modifier onlyOwner() {
        require(msg.sender ==_owner , "Solo puede llamar el owner");
        _;
    }

    /*
    El término "mintear" proviene del inglés "mint", que significa "acuñar" o "crear"
    en el contexto de monedas o activos
    */
    function mint(address destDir, uint256 tokensEmitidos) external  onlyOwner {
        //Tenemos que verificar que la dirección del destino exista
        require(destDir != address(0), "La direccion destino no es valida");
        //Verificar que no hayan excedido el numero máximo de tokens
         require(mintedTokens+tokensEmitidos<=maxTokens, "No se pueden emitir mas tokens!");
         mintedTokens += tokensEmitidos;

         /*FUNCIÓN MINT DE ERC20*/
         _mint(destDir, tokensEmitidos);
    }

    function burn(address destDir, uint256 tokensEliminados) external onlyOwner{
        //Tenemos que verificar que la dirección del destino exista
        require(destDir != address(0), "La direccion destino no es valida");
        //Verificar que no hayan excedido el numero máximo de tokens
        require(tokensEliminados>0, "No se puede eliminar 0 ni un numero negativo de tokens.");

        /*FUNCIÓN BURN DE ERC20*/
        _burn(destDir, tokensEliminados);
    }

    function getTokenPrice() external view returns (uint256) { return tokenPrice;}
    function getMaxTokens() external view returns (uint256){return maxTokens; }
}