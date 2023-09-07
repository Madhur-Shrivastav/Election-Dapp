//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Election2 is ERC721URIStorage, Pausable {
    address payable public manager;
    address public winner;
    uint256 public candidatefee = 0.5 ether;
    uint256 public voterfee = 0.1 ether;
    uint256 public totalvotes;
    using Counters for Counters.Counter;
    Counters.Counter private tokenID;

    constructor() ERC721("Voting Token", "VOTE") {
        manager = payable(msg.sender);
    }

    modifier OnlyManager() {
        require(msg.sender == manager, "You are not the manager!");
        _;
    }
    modifier NotManager() {
        require(msg.sender != manager, "You are the manager!");
        _;
    }

    function getmanager() external view returns (address) {
        return manager;
    }

    struct Candidate {
        uint256 candidateID;
        string candidateURI;
        address candidateaddress;
        uint256 votes;
    }

    Candidate[] candidates;
    mapping(address => bool) public hasparticipated;

    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    function participate(string memory candidateuri)
        external
        payable
        NotManager
        whenNotPaused
    {
        require(
            hasparticipated[msg.sender] == false,
            "You have already participated as an election candidate!"
        );
        require(
            isvoter[msg.sender] == false,
            "You are a voter, so you cannot participate as an election candidate!"
        );
        require(
            msg.value >= candidatefee,
            "You need to pay at least 0.5 ETH in order to participate in the elections!"
        );
        payable(msg.sender).transfer(msg.value - candidatefee);
        manager.transfer(candidatefee);
        tokenID.increment();
        uint256 newcandidateID = tokenID.current();
        _safeMint(msg.sender, newcandidateID);
        _setTokenURI(newcandidateID, candidateuri);
        candidates.push(Candidate(newcandidateID, candidateuri, msg.sender, 0));
        hasparticipated[msg.sender] = true;
    }

    struct Voter {
        uint256 voterID;
        string voterURI;
        address voteraddress;
    }
    Voter[] voters;
    mapping(address => bool) public hasvoted;
    mapping(address => bool) public isvoter;

    function createVoterID(string memory voteruri)
        external
        payable
        NotManager
        whenNotPaused
    {
        require(
            hasparticipated[msg.sender] == false,
            "You cannot vote as you have participated as an election candidate!"
        );
        require(isvoter[msg.sender] == false, "You already have a voter ID!");
        require(
            msg.value >= voterfee,
            "You need to pay 0.1 ETH to create a voter ID!"
        );
        payable(msg.sender).transfer(msg.value - voterfee);
        manager.transfer(voterfee);
        tokenID.increment();
        uint256 newvoterID = tokenID.current();
        _safeMint(msg.sender, newvoterID);
        _setTokenURI(newvoterID, voteruri);
        voters.push(Voter(newvoterID, voteruri, msg.sender));
        isvoter[msg.sender] = true;
        hasvoted[msg.sender] = false;
    }

    function getVoters() external view returns (Voter[] memory) {
        return voters;
    }

    function indexOf(uint256 candidateid) public view returns (uint256) {
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].candidateID == candidateid) {
                return i;
            }
        }
        return (candidates.length - candidates.length) - 1;
    }

    function vote(uint256 candidateid) external NotManager whenNotPaused {
        uint256 index = indexOf(candidateid);
        require(index >= 0, "Candidate ID does not exist!");
        require(
            hasparticipated[msg.sender] == false,
            "You cannot vote as you are an election participant!"
        );
        require(hasvoted[msg.sender] == false, "You have already voted!");
        Candidate storage candidate = candidates[index];
        candidate.votes++;
        totalvotes++;
        hasvoted[msg.sender] = true;
    }

    function setWinner() external OnlyManager {
        require(voters.length>0 && candidates.length>0,"The elections have not started yet!");
        require(totalvotes==voters.length,"Not all voters have voted yet!");
        uint256 max;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].votes > max) {
                max = candidates[i].votes;
            }
        }
        for (uint256 j = 0; j < candidates.length; j++) {
            if (candidates[j].votes == max) {
                winner = candidates[j].candidateaddress;
                
            }
        }
    }

    function getWinner() external view OnlyManager returns(address){
        require(winner!=address(0),"The winner has not been set yet!");
        require(totalvotes == voters.length, "Not all voters have voted yet!");
        return winner;
    }

    function reset() public OnlyManager {
        require(winner != address(0), "The winner has not been declared!");
        winner = address(0);

        for (uint256 i = 0; i < candidates.length; i++) {
            hasparticipated[candidates[i].candidateaddress] = false;
        }
        for (uint256 i = 0; i < voters.length; i++) {
            hasvoted[voters[i].voteraddress] = false;
            isvoter[voters[i].voteraddress] = false;
        }

        delete candidates;
        delete voters;
        totalvotes = 0;
    }

    function pause() external OnlyManager {
        _pause();
    }

    function unpause() external OnlyManager {
        _unpause();
    }
}
