pragma solidity ^0.5.0;

import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract Cirrus is ERC20 {
    constructor (string memory name, string memory symbol, address initialRecipient, uint256 initialTransfer) public {
        _name = name;
        _symbol = symbol;
        _mint(msg.sender, 100000);
        // initialize account with DROP tokens
        _transfer(address(this), initialRecipient, initialTransfer);
    }

    // ERC20 naming details
    string private _name;
    string private _symbol;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Sensors
    struct Sensor {
        uint256 sensorUuid;
        uint256 lastUpdated; // block number
        uint256 totalUsage;
        uint256 priorUsage;
        address sensorOwner;
    }

    Sensor[] public sensors;
    mapping (uint256 => address) public sensorToOwner;
    mapping (address => uint256[]) public ownerToSensor;
    mapping (uint256 => uint256) public uuidToIndex;

    // register sensor
    function registerSensor(uint256 uuid, address sensorOwner, uint256 usage) public {
        uuidToIndex[uuid] = sensors.length;
        sensorToOwner[uuid] = sensorOwner;
        ownerToSensor[sensorOwner].push(uuid);
        sensors.push(Sensor(uuid, block.number, usage, usage, sensorOwner));
    }

    function updateUsage(uint256 uuid, uint256 currentUsage) public {
        uint256 sensorIndex = uuidToIndex[uuid];
        sensors[sensorIndex].lastUpdated = block.number;
        sensors[sensorIndex].priorUsage = sensors[sensorIndex].totalUsage;
        sensors[sensorIndex].totalUsage = currentUsage;
    }

    // Bounties
    // both bounties and competitions currently focus on measurements from a single sensor.
    struct Bounty {
        address ownerAddress;
        uint256 bountyValue;
        uint256 bountyQty;
        uint256 targetUsage;
        bool bountyActive;
        }

    Bounty[] public bounties;
    mapping (address => uint256) public addressToStartBounty; // stores bounty index
    mapping (address => uint256) public addressToStartUsage;
    mapping (uint256 => uint256) public bountyClaimsRemaining;

    function createBounty(uint256 value, uint256 qty, uint256 target) public {
        bounties.push(Bounty(msg.sender, value, qty, target, true));
    }

    function beginBounty(uint256 bountyIndex, uint256 sensorUuid) public {
        addressToStartBounty[msg.sender] = bountyIndex;
        uint256 sensorIndex = uuidToIndex[sensorUuid];
        addressToStartUsage[msg.sender] = sensors[sensorIndex].totalUsage;
    }

    function claimBounty(uint256 bountyIndex, uint256 sensorUuid) public returns (bool) {
        addressToStartBounty[msg.sender] = bountyIndex;
        require(bounties[bountyIndex].bountyQty > 1, 'all bounties claimed!');
        uint256 sensorIndex = uuidToIndex[sensorUuid];
        if ((sensors[sensorIndex].totalUsage - addressToStartUsage[msg.sender]) >= bounties[bountyIndex].bountyValue) {
            transferFrom(address(this), msg.sender, bounties[bountyIndex].bountyValue);
        }
        else {return false;}
    }

    // Competition
    struct Competition {
        address ownerAddress;
        uint256 prizeValue;
        uint256 numberOfWinners;
        bool active;
    }

    Competition[] public competitions;

    // for now, only one competition can be active at a time
    address[] public entrants;
    mapping (address => uint256) public startUsage;
    mapping (address => uint256) public currentSavings;

    function createCompetition(uint256 value, uint256 winners) public {
        competitions.push(Competition(msg.sender, value, winners, true));
    }

    function beginCompetition(uint256 sensorUuid) public {
        entrants.push(msg.sender);
        uint256 sensorIndex = uuidToIndex[sensorUuid];
        startUsage[msg.sender] = sensors[sensorIndex].totalUsage;
    }


    // TODO: FINISH COMPETITION RANKING
    // TODO: lookup owner of usage (reverse lookup address by savings)
    // function rank() public {
    //     if (data.length == 0)
    //         return;
    //     quickSort(data, 0, data.length - 1);
    // }

    // function quickSort(uint[] storage arr, uint left, uint right) internal {
    //     uint i = left;
    //     uint j = right;
    //     uint pivot = arr[left + (right - left) / 2];
    //     while (i <= j) {
    //         while (arr[i] < pivot) i++;
    //         while (pivot < arr[j]) j--;
    //         if (i <= j) {
    //             (arr[i], arr[j]) = (arr[j], arr[i]);
    //             i++;
    //             j--;
    //         }
    //     }
    //     if (left < j)
    //         quickSort(arr, left, j);
    //     if (i < right)
    //         quickSort(arr, i, right);
    // }

    // TODO: DECLARE WINNERS
    // check status (rankings)
    // close competition & declare winner

}