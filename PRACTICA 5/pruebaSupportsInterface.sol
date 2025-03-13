// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}

//No sabía cómo impleentarlo, lo he tenido que buscar...
contract PruebaSupportsInterface{

    bytes4 public constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd; 

    function pruebaSupportsInterface(address monsterToken) external pure returns (bool, bool, bool) {
        ERC165 token = ERC165(monsterToken);
        bool supportsERC165 = token.supportsInterface(ERC165_INTERFACE_ID);
        bool supportsERC721 = token.supportsInterface(ERC721_INTERFACE_ID);
        bool supportsRandom = token.supportsInterface(0x12345678); // ID aleatorio para probar false
        return (supportsERC165, supportsERC721, supportsRandom);
    }


}