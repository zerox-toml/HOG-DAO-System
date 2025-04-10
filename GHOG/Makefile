deploy-ghog:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/GHOG.sol:GHOG --constructor-args 
    forge create --broadcast contracts/GHOG.sol:GHOG --rpc-url $SEPOLIA_URL --account baseman
deploy-ghogrewardpool:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/distribution/GHogRewardPool.sol:GHogRewardPool --constructor-args $GHOG_ADDRESS $DEV_FUND_ADDRESS $POOL_INFO
    forge create --broadcast --rpc-url $SEPOLIA_URL contracts/distribution/GHogRewardPool.sol:GHogRewardPool --account baseman --constructor-args $GHOG_ADDRESS $DEV_FUND_ADDRESS $POOL_START_TIME


# BASE Network
#  deploy GHOG RewardPool Contract
forge create --broadcast --rpc-url $BASE_SEPOLIA_RPC contracts/distribution/GHogRewardPool.sol:GHogRewardPool --constructor-args $GHOG_ADDRESS $DEV_FUND_ADDRESS $POOL_INFO

# Deploy GHOG Token Contract
deploy-ghog-base:
    forge create --broadcast contracts/GHOG.sol:GHOG --rpc-url $BASE_SEPOLIA_RPC --account baseman
# 0xB37e29527941191bcA11fBb696aF8e257cCcd49d

# verify
verify-ghog-base:
    forge verify-contract 0xB37e29527941191bcA11fBb696aF8e257cCcd49d contracts/GHOG.sol:GHOG --chain 84532 --watch

# verify ghogrewardpool
verify-ghogrewardpool:    
    forge verify-contract 0xb8b79B96fAF5B2283D8DcCD0e879018896AD058e --constructor-args $(cast abi-encode "constructor(address, address, uint256)" 0xE69A8A6cD11D46BE328F4d6b211032f836f89743 0x77E7d0D483268708556de04AC1FBe7f43beb649B 1744314000)  contracts/distribution/GHogRewardPool.sol:GHogRewardPool --chain 11155111 --watch 