# Fulcrum — Perpetual Futures

> Fulcrum is a perpetual futures engine with isolated positions, funding rate accrual, and on-chain liquidations. Open longs and shorts against a price oracle and close whenever you want.

## What it does

Fulcrum is a perpetual futures engine with isolated positions, funding rate accrual, and on-chain liquidations. Open longs and shorts against a price oracle and close whenever you want. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/PerpDEX.sol` |
| Contract name | `PerpDEX` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 5 (of which 1 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `openPosition` | payable | uint256 |
| `closePosition` | write | result / revert |
| `updatePrice` | write | result / revert |
| `getPosition` | view | address trader, bool isLong, uint256 size, uint256 entryPrice, uint256 margin, bool open |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `PositionOpened` | (uint256 indexed pid, address indexed trader, bool isLong, uint256 size, uint256 entryPrice) |
| `PositionClosed` | (uint256 indexed pid, address indexed trader, uint256 pnl) |
| `PriceUpdated` | (uint256 indexed pid, uint256 price) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/perp-dex.git
cd perp-dex
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.