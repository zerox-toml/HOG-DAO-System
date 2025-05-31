# 🐗 HOG DAO System

**HOG DAO System** is a robust smart contract suite for deploying an **algorithmic stablecoin with decentralized governance**. Inspired by systems like FRAX and OlympusDAO, this project provides the foundation for a self-regulating currency with automated supply control and staking incentives.

## 🧠 Overview

This system includes:

- 🪙 **HOG Token** — An elastic-supply stablecoin with mint/burn capabilities.
- 🏛️ **HOG DAO** — A decentralized governance system for protocol control.
- 💰 **Treasury Contracts** — Manage reserves, revenue, and fund allocations.
- 🔒 **Staking Contracts** — Lock tokens and receive rebasing rewards.
- 📉 **Bonding Contracts** — Protocol-owned liquidity acquisition through discounted bonds.
- 📊 **Price Oracles** — Track and respond to market conditions for dynamic control.

## 🔧 Key Components

| Contract | Description |
|----------|-------------|
| `Hog.sol` | Core ERC20 token with mint/burn mechanics and supply control logic. |
| `Treasury.sol` | Manages reserves and interacts with bonding/staking modules. |
| `.sol` | Allows users to stake HOG and earn yield via rebasing. |
| `BHOG.sol` | Enables discounted HOG purchases in exchange for assets (e.g., DAI, USDC). |
| `Mansory.sol` | Governance voting mechanism to propose and execute protocol changes. |
| `PriceOracle.sol` | Pulls external price feeds to inform monetary policy. |

## 🧬 Features

- **Algorithmic Supply Expansion/Contraction**  
  Controlled issuance and burning of HOG to maintain peg.

- **Protocol-Owned Liquidity**  
  Sustainable liquidity acquisition via bonding.

- **Decentralized Governance**  
  Token-based voting mechanism for key upgrades and treasury allocation.

- **Rebasing Mechanism**  
  Stakers receive rewards that adjust according to protocol profitability.

- **Treasury-backed Value**  
  Ensures intrinsic floor price through reserve collateral.

## 🛠️ Getting Started

### Prerequisites

- Node.js ≥ 18.x
- Foundry 
- Solidity ≥ 0.8.0
- Sepolia


