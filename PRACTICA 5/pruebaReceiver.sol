// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//He tenido que añadir calldata (como en la interfaz de la primera parte de la práctica porque si no no me compilaba.
interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from,uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}


contract PruebaReceiver is ERC721TokenReceiver{

    function onERC721Received(address _operator, address _from,uint256 _tokenId, bytes calldata _data) external returns(bytes4){
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}