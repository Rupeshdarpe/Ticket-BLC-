// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Ticketing contract for selling VIP and Silver tickets for events
/// @author [author name]
/// @notice This contract allows event organizers to create events and sell tickets to users
/// @dev This contract is written in Solidity version 0.8.0
contract Ticketing {
    event EventCreated(address indexed owner, uint256 indexed eventId, string name, uint256 vipTicketPrice, uint256 silverTicketPrice, uint256 eventDate);
    event TicketBought(address indexed buyer, string category, uint256 ticketPrice);

    /// @notice Struct for storing information about a ticket
    struct Ticket {
        uint256 ticketId;
        bool isSold;
        uint256 eventId;
        uint256 price;
        string category;
        string eventName;
        uint256 eventDate;
        string eventVenue;
    }

    /// @notice Struct for storing information about an event
    struct Event {
        uint256 eventId;
        address owner;
        uint256 numVipTickets;
        uint256 numSilverTickets;
        uint256 vipTicketPrice;
        uint256 silverTicketPrice;
        uint256 vipSold;
        uint256 silverSold;
        uint256 sellingDuration;
        string eventName;
        uint256 eventDate;
        string eventVenue;
        Ticket[] vipTickets;
        Ticket[] silverTickets;
    }

    /// @notice Struct for storing information about an order
    struct MyOrder {
        uint timestamp;
        Ticket ticket;
    }

    mapping(uint256 => Event) public events;
    mapping(address => uint256) public orderCount;
    mapping(address => mapping(uint256 => MyOrder)) public myOrders;
    mapping(address => uint256) public myEventCount;
    mapping(address => mapping(uint256 => Event)) public myEvents;

    uint256 public numEvents;
    uint256 constant SELLINGDURATION = 10 minutes;

    function addEvent(
        uint256 _numVipTickets,
        uint256 _numSilverTickets,
        uint256 _vipTicketPrice,
        uint256 _silverTicketPrice,
        string memory _eventName,
        uint256 _eventDate,
        string memory _eventVenue
    ) public {
        Event storage newEvent = events[numEvents];
        newEvent.eventId = numEvents;
        newEvent.owner = msg.sender;
        newEvent.numVipTickets = _numVipTickets;
        newEvent.numSilverTickets = _numSilverTickets;
        newEvent.vipTicketPrice = _vipTicketPrice;
        newEvent.silverTicketPrice = _silverTicketPrice;
        newEvent.sellingDuration = block.timestamp + SELLINGDURATION;
        newEvent.eventName = _eventName;
        newEvent.eventDate = _eventDate;
        newEvent.eventVenue = _eventVenue;

        for (uint256 i = 0; i < _numVipTickets; i++) {
            newEvent.vipTickets.push(Ticket(i, false, numEvents, _vipTicketPrice, "VIP", _eventName, _eventDate, _eventVenue));
        }
        for (uint256 i = 0; i < _numSilverTickets; i++) {
            newEvent.silverTickets.push(Ticket(i, false, numEvents, _silverTicketPrice, "Silver", _eventName, _eventDate, _eventVenue));
        }

        numEvents++;
        myEventCount[msg.sender]++;
        myEvents[msg.sender][myEventCount[msg.sender]] = newEvent;

        emit EventCreated(msg.sender, newEvent.eventId, newEvent.eventName, newEvent.vipTicketPrice, newEvent.silverTicketPrice, _eventDate);
    }

    function buyTicket(uint256 _eventId, string memory _category) public payable {
        Event storage eventToBuy = events[_eventId];
        require(block.timestamp <= eventToBuy.sellingDuration, "Ticket Selling Duration has passed");

        Ticket[] storage ticketsToBuy;
        uint256 numTicketsSold;
        uint256 ticketPrice;

        if (keccak256(abi.encodePacked(_category)) == keccak256(abi.encodePacked("VIP"))) {
            require(eventToBuy.vipSold < eventToBuy.numVipTickets, "All VIP tickets are sold out");
            ticketsToBuy = eventToBuy.vipTickets;
            numTicketsSold = eventToBuy.vipSold;
            ticketPrice = eventToBuy.vipTicketPrice;
            eventToBuy.vipSold++;
        } else if (keccak256(abi.encodePacked(_category)) == keccak256(abi.encodePacked("Silver"))) {
            require(eventToBuy.silverSold < eventToBuy.numSilverTickets, "All Silver tickets are sold out");
            ticketsToBuy = eventToBuy.silverTickets;
            numTicketsSold = eventToBuy.silverSold;
            ticketPrice = eventToBuy.silverTicketPrice;
            eventToBuy.silverSold++;
        } else {
            revert("Invalid ticket category");
        }

        require(msg.value == ticketPrice, "Incorrect amount sent");
        payable(eventToBuy.owner).transfer(ticketPrice);

        Ticket storage ticketToBuy = ticketsToBuy[numTicketsSold];
        require(!ticketToBuy.isSold, "Ticket already sold");
        ticketToBuy.isSold = true;

        MyOrder memory order = MyOrder(block.timestamp, ticketToBuy);
        orderCount[msg.sender]++;
        myOrders[msg.sender][orderCount[msg.sender]] = order;

        emit TicketBought(msg.sender, _category, ticketPrice);
    }

    function getEvent(uint256 _eventId) public view returns (
        address eventOwner,
        uint256 eventId,
        uint256 numVipTickets,
        uint256 numSilverTickets,
        uint256 vipSold,
        uint256 silverSold,
        uint256 sellingDuration,
        string memory eventName,
        uint256 eventDate,
        string memory eventVenue
    ) {
        Event storage eventToGet = events[_eventId];
        return (
            eventToGet.owner,
            eventToGet.eventId,
            eventToGet.numVipTickets,
            eventToGet.numSilverTickets,
            eventToGet.vipSold,
            eventToGet.silverSold,
            eventToGet.sellingDuration,
            eventToGet.eventName,
            eventToGet.eventDate,
            eventToGet.eventVenue
        );
    }

    function getAllEvents() public view returns (
        uint256[] memory eventIds,
        address[] memory owners,
        string[] memory eventNames,
        uint256[] memory eventDates,
        string[] memory eventVenues
    ) {
        eventIds = new uint256[](numEvents);
        owners = new address[](numEvents);
        eventNames = new string[](numEvents);
        eventDates = new uint256[](numEvents);
        eventVenues = new string[](numEvents);

        for (uint256 i = 0; i < numEvents; i++) {
            eventIds[i] = events[i].eventId;
            owners[i] = events[i].owner;
            eventNames[i] = events[i].eventName;
            eventDates[i] = events[i].eventDate;
            eventVenues[i] = events[i].eventVenue;
        }
    }
}