// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract crowdFunder{
    struct Campaign{
        address payable creator;
        uint fundingGoal;
        uint pledged;
        uint deadline;
        bool withdrawn;
    }

    mapping(uint => Campaign) public campaigns;
    uint[] public campaignIDs;
    uint public nextCampaignID;

    event campaignCreated(uint ID, address creator, uint fundingGoal, uint deadline);

    event donationReceived(uint ID, address donor, uint amount);

    event fundsWithdrawal(uint ID, address creator, uint amount);

    function createCampaign(uint fundingGoal, uint duration) public{
        require(fundingGoal > 0, "Goal must be greater than zero");
        require(duration > 0, "Deadline must be greater than zero");

        uint deadline = block.timestamp + duration;
        campaigns[nextCampaignID] = Campaign({
            creator : payable(msg.sender),
            fundingGoal : fundingGoal,
            pledged : 0,
            deadline : deadline,
            withdrawn : false
        });

        campaignIDs.push(nextCampaignID);

        emit campaignCreated (nextCampaignID, msg.sender, fundingGoal, deadline);

        nextCampaignID++;
    }

    function donatetoCampaign(uint campaignID) public payable{
        require(msg.value > 0, "You have to make a donation");
        Campaign storage campaign = campaigns[campaignID];
        require(block.timestamp < campaign.deadline, "Campaign has ended");

        campaign.pledged += msg.value;

        emit donationReceived(campaignID, msg.sender, msg.value);
    }

    function isCampaignSuccessful(uint campaignID) public view returns(bool){
        Campaign storage campaign = campaigns[campaignID];
        return campaign.pledged >= campaign.fundingGoal && block.timestamp >= campaign.deadline;
    }

    function withdrawFunds(uint campaignID) public{
        Campaign storage campaign = campaigns[campaignID];
        require(block.timestamp >= campaign.deadline, "Campaign has not ended");
        require(campaign.pledged >= campaign.fundingGoal, "Funding goal not yet achieved");
        require(!campaign.withdrawn, "You have withdrawn");
        require(msg.sender == campaign.creator, "Only the creator of the campaign can withdraw");

        campaign.withdrawn = true;

        uint amount = campaign.pledged;
        campaign.pledged = 0;

        campaign.creator.transfer(amount);

        emit fundsWithdrawal(campaignID, campaign.creator, amount);
    }

    function getCampaignIDs() public view returns(uint[] memory){
        return campaignIDs;
    }

}