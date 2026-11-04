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
    struct Position { address trader;bool isLong;uint256 size;uint256 entryPrice;uint256 margin;bool open; }
    Position[] public positions;mapping(address=>uint256[]) public traderPositions;mapping(uint256=>uint256) public priceFeed;uint256 public positionCount;uint256 public totalVolume;uint256 public marketPrice;uint256 public priceUpdatedAt;uint256 public totalOpenMargin;
    event PositionOpened(uint256 indexed pid,address indexed trader,bool isLong,uint256 size,uint256 entryPrice);event PositionClosed(uint256 indexed pid,address indexed trader,uint256 payout);event PriceUpdated(uint256 indexed pid,uint256 price);event MarketPriceUpdated(uint256 price);event ReserveFunded(uint256 amount);
    function fundReserve() external payable onlyOwner { require(msg.value>0,"Zero funding");emit ReserveFunded(msg.value); }
    function setMarketPrice(uint256 price) external onlyOwner { _price(price); }
    function _price(uint256 price) private { require(price>0&&price<=1e30,"Invalid price");marketPrice=price;priceUpdatedAt=block.timestamp;emit MarketPriceUpdated(price); }
    function openPosition(bool isLong,uint256 size,uint256 entryPrice,uint256 margin) external payable nonReentrant returns(uint256 pid) {
        require(margin>0&&margin<=1e30&&msg.value==margin,"Invalid margin");require(size>0&&size<=margin*10,"Leverage exceeds 10x");require(entryPrice==marketPrice&&entryPrice>0&&block.timestamp<=priceUpdatedAt+1 days,"Stale or incorrect price");require(address(this).balance>=2*(totalOpenMargin+margin),"Insufficient counterparty reserve");pid=positions.length;positions.push(Position(msg.sender,isLong,size,entryPrice,margin,true));totalOpenMargin+=margin;totalVolume+=size;positionCount++;traderPositions[msg.sender].push(pid);emit PositionOpened(pid,msg.sender,isLong,size,entryPrice);
    }
    function closePosition(uint256 pid,uint256 closePrice) external nonReentrant {
        Position storage p=positions[pid];require(p.open&&p.trader==msg.sender,"Not your open position");require(closePrice==marketPrice&&closePrice>0&&block.timestamp<=priceUpdatedAt+1 days,"Stale or incorrect price");int256 delta=int256(closePrice)-int256(p.entryPrice);int256 pnl=delta*int256(p.size)/int256(p.entryPrice);if(!p.isLong)pnl=-pnl;if(pnl>int256(p.margin))pnl=int256(p.margin);if(pnl< -int256(p.margin))pnl=-int256(p.margin);uint256 payout=uint256(int256(p.margin)+pnl);p.open=false;totalOpenMargin-=p.margin;if(payout>0){(bool ok,)=msg.sender.call{value:payout}("");require(ok,"Payout failed");}emit PositionClosed(pid,msg.sender,payout);
    }
    function updatePrice(uint256 pid,uint256 newPrice) external onlyOwner { require(pid<positions.length,"Unknown position");_price(newPrice);priceFeed[pid]=newPrice;emit PriceUpdated(pid,newPrice); }
    function closeStalePosition(uint256 pid) external nonReentrant {Position storage p=positions[pid];require(p.open&&p.trader==msg.sender,"Not your position");require(block.timestamp>priceUpdatedAt+1 days,"Price is fresh");p.open=false;totalOpenMargin-=p.margin;(bool ok,)=msg.sender.call{value:p.margin}("");require(ok,"Refund failed");emit PositionClosed(pid,msg.sender,p.margin);}
    function withdrawReserve(uint256 amount) external onlyOwner nonReentrant { require(address(this).balance>=2*totalOpenMargin+amount,"Reserved for positions");(bool ok,)=owner().call{value:amount}("");require(ok,"Withdraw failed"); }
    function getPosition(uint256 pid) external view returns(address trader,bool isLong,uint256 size,uint256 entryPrice,uint256 margin,bool open) { Position storage p=positions[pid];return(p.trader,p.isLong,p.size,p.entryPrice,p.margin,p.open); }
}

