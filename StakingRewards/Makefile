deploy-base:
	forge create contracts/StakingRewards.sol:StakingRewards --private-key $PRIVATE_KEY --rpc-url $BASE_URL --broadcast --constructor-args $REWARDS_TOKEN $STAKING_TOKEN 

deploy-sepolia:
	forge create contracts/StakingRewards.sol:StakingRewards --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_URL --broadcast --constructor-args 0x008769eE2D69B2B7da69d04fD1dbD17CFC3353b3 0xa54b32E8432d5908c2f44e88d54Ba52835e7377b

deploy-sample:
	forge create contracts/sample.sol:Sample --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_URL --broadcast
deploy-sepolia-script:
	forge script script/StakingReward.s.sol:DeployStakingRewards --rpc-url $SEPOLIA_URL --broadcast --private-key $PRIVATE_KEY 

verify-base:
	forge verify-contract --chain-id 84532 --watch --constructor-args $(cast abi-encode "constructor(address,address)" 0xD2a3d41d2c01426C53d4e272f231133f167b2C87 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) --verifier-url https://api-testnet.cronoscan.com/QsE9DiSy4CWOJpMpowvc6LoYZFvlalBY --compiler-version v0.8.19 --watch ./src/NFT.sol:NFT

verify-sepolia:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0x008769eE2D69B2B7da69d04fD1dbD17CFC3353b3 0xa54b32E8432d5908c2f44e88d54Ba52835e7377b) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0x24AF361Eef27Bc32D18Ed19062746092D778Fda5 \
    contracts/StakingRewards.sol:StakingRewards