// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IExecutableProposal {
    function executeProposal(uint256 proposalId, uint256 numVotes, uint256 numTokens) external payable;
}

contract ExecutableProposal is IExecutableProposal {
    uint256 public proposalId;
    uint256 public numVotes;
    uint256 public numTokens;
    uint256 public receivedFunds;

    function executeProposal(uint256 _proposalId, uint256 _numVotes, uint256 _numTokens) external payable override {
        proposalId = _proposalId;
        numVotes = _numVotes;
        numTokens = _numTokens;
        receivedFunds = msg.value;
    }

    receive() external payable {}
}