deploy-base:
	forge create contracts/StakingRewards.sol:StakingRewards --private-key $PRIVATE_KEY --rpc-url $BASE_URL --broadcast --constructor-args $REWARDS_TOKEN $STAKING_TOKEN 
    forge create contracts/StakingRewards.sol:StakingRewards --account baseman --rpc-url $SEPOLIA_URL --broadcast --constructor-args $REWARDS_TOKEN $STAKING_TOKEN


verify-base:
	forge verify-contract --chain-id 84532 --watch --constructor-args $(cast abi-encode "constructor(address,address)" 0xD2a3d41d2c01426C53d4e272f231133f167b2C87 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) --verifier-url https://api-testnet.cronoscan.com/QsE9DiSy4CWOJpMpowvc6LoYZFvlalBY --compiler-version v0.8.19 --watch ./src/NFT.sol:NFT
