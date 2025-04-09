deploy-ghog:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/GHOG.sol:GHOG --constructor-args 

deploy-ghogrewardpool:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/distribution/GHogRewardPool.sol:GHogRewardPool --constructor-args $GHOG_ADDRESS $DEV_FUND_ADDRESS $POOL_INFO


verify-ghog:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor()" ) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0x008769eE2D69B2B7da69d04fD1dbD17CFC3353b3 \
    contracts/GHOG.sol:GHOG	

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