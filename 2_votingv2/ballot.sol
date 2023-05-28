// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Ballot Contrast
/// @author umiotter
/// @notice a ballot demo 
contract Ballot {
    struct Voter{
        uint weight; // check vote is valid or not
        bool voted; // check whether is voted
        address delegate; // delegate vote to somebody
        uint vote; // record voted proposal 
    }

    struct Proposal{
        bytes32 name; // proposal name
        uint voteCount; // proposal count
    }

    address public chairperson; // esmpowering users to vote

    mapping(address => Voter) public voters; // ballot participants

    Proposal[] public proposals;

    /// @notice setting contract deployer as chairperson, init proposal list
    /// @param proposalNames proposal name list
    constructor(bytes32[] memory proposalNames){
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        for(uint i = 0; i < proposalNames.length; i++){
            proposals.push(Proposal({
                name: proposalNames[i], 
                voteCount: 0
                })
            );
        }
    }
    /// @notice esmpowering a address the right to vote by chair
    /// @param _voter authorized Address
    function esmpowerToVote(address _voter) external {
        require(
            msg.sender == chairperson, 
            "Only chairperson can give right to vote."
        );
        require(
            !voters[_voter].voted, 
            "The voter already voted."
        );
        require(
            voters[_voter].weight == 0,
            "The voter hasn't right to vote."
        );
        voters[_voter].weight = 1;
    }

    /// @notice delegate somebody to vote
    /// @param _to authorized Address
    function setDelegatee(address _to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have not right to vote.");
        require(!sender.voted, "You have voted.");
        require(sender.delegate == address(0), "You have already set a delegatee.");

        require(_to != msg.sender, "Self-delegation is disallowed.");

        // delegate is deliverable
        // closed-loop delegation is not allowed
        while(voters[_to].delegate != address(0)) {
            _to = voters[_to].delegate;
            require(_to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegatee = voters[_to];

        // voter can't delegate to accounts that cannot vote
        require(delegatee.weight != 0, "Delegatee haven't right to vote.");

        // once sender delegatee to voted, it cannot vote.
        sender.voted = true;
        sender.delegate = _to;

        // if delegatee has voted, add the voted proposal directly
        if(delegatee.voted) {
            proposals[delegatee.vote].voteCount += sender.weight;
        } else {
            delegatee.weight += sender.weight;
        }
    }

    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have not right to vote.");
        require(!sender.voted, "You have voted or delegated.");

        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;

    }

    function currentWinningProposal() public view returns(uint[] memory _result){
        uint winningVoteCount = 0;
        // count amount of most voted proposals
        for(uint p = 0; p < proposals.length; p++){
            if(proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
            }
        }
        
        // fixing _result length by counting equivalent proposals
        uint equivalentProposalCount;
        for(uint p = 0; p < proposals.length; p++){
            if(proposals[p].voteCount == winningVoteCount){
                equivalentProposalCount ++;
            }
        }
        _result = new uint[](equivalentProposalCount);

        // store equivalent proposal
        uint index = 0;
        for(uint i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount == winningVoteCount){
                _result[index] = i;
                index++;
            }
        }
    }

    function winnerName() public view returns(bytes32[] memory _winnerName){
        uint[] memory winners = currentWinningProposal();
        _winnerName = new bytes32[](winners.length);
        for(uint i; i < _winnerName.length; i++){
            _winnerName[i] = proposals[winners[i]].name;
        }
    }


}