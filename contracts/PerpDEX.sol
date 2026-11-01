// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

contract PerpDEX is ReentrancyGuard, Ownable {
    struct Position {
        address trader;
        bool isLong;
        uint256 size;
        uint256 entryPrice;
        uint256 margin;
        bool open;
    }
    Position[] public positions;
    mapping(address => uint256[]) public traderPositions;
    uint256 public positionCount;
    uint256 public totalVolume;
    mapping(uint256 => uint256) public priceFeed;

    event PositionOpened(uint256 indexed pid, address indexed trader, bool isLong, uint256 size, uint256 entryPrice);
    event PositionClosed(uint256 indexed pid, address indexed trader, uint256 pnl);
    event PriceUpdated(uint256 indexed pid, uint256 price);

    function openPosition(bool isLong, uint256 size, uint256 entryPrice, uint256 margin)
        external payable nonReentrant returns (uint256) {
        require(size > 0, "Zero size");
        require(margin > 0, "Zero margin");
        require(msg.value >= margin, "Insufficient margin");
        Position storage p = positions.push();
        p.trader = msg.sender;
        p.isLong = isLong;
        p.size = size;
        p.entryPrice = entryPrice;
        p.margin = margin;
        p.open = true;
        uint256 pid = positions.length - 1;
        positionCount = pid + 1;
        traderPositions[msg.sender].push(pid);
        totalVolume += size * entryPrice;
        emit PositionOpened(pid, msg.sender, isLong, size, entryPrice);
        return pid;
    }

    function closePosition(uint256 pid, uint256 closePrice) external nonReentrant {
        Position storage p = positions[pid];
        require(p.open, "Position closed");
        require(p.trader == msg.sender, "Not your position");
        p.open = false;
        int256 pnl = p.isLong ? int256(closePrice - p.entryPrice) * int256(p.size) : int256(p.entryPrice - closePrice) * int256(p.size);
        uint256 payout = p.margin + (pnl > 0 ? uint256(pnl) : 0);
        emit PositionClosed(pid, msg.sender, payout);
    }

    function updatePrice(uint256 pid, uint256 newPrice) external onlyOwner {
        priceFeed[pid] = newPrice;
        emit PriceUpdated(pid, newPrice);
    }

    function getPosition(uint256 pid) external view returns (address trader, bool isLong, uint256 size, uint256 entryPrice, uint256 margin, bool open) {
        Position storage p = positions[pid];
        return (p.trader, p.isLong, p.size, p.entryPrice, p.margin, p.open);
    }
}
