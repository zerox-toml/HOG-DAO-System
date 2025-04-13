deploy-hog:
	forge create --broadcast --rpc-url $SEPOLIA_URL --account baseman contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT
# 0xb3B1fBEE53732174fE9Eca63d76660CA4
verify-hog:
    forge verify-contract 0xb3B1fBEE53732174fE9Eca63d76660CA40974d55 --constructor-args $(cast abi-encode "constructor(address,address)" 0xF921b7c44D850282985a200d538015E21f737d6C 0xaa8e23fb1079ea71e0a56f48a2aa51851d8433d0) contracts/HOG.sol:HOG --chain 11155111 --watch
deploy-HogGenesisRewardPool:
	forge create --broadcast --rpc-url $SEPOLIA_URL --account baseman contracts/distribution/HogGenesisRewardPool.sol:HogGenesisRewardPool --constructor-args $HOG_ADDRESS $MIM_ADDRESS $FEE_ADDRESS $POOL_START_TIME
# 0xBC58DD52b11F9892BbA042f19186dE03852170B1
verify-HogGenesisRewardPool:
	forge verify-contract 0xBC58DD52b11F9892BbA042f19186dE03852170B1 --constructor-args $(cast abi-encode "constructor(address,address,address,uint256)" 0xb3B1fBEE53732174fE9Eca63d76660CA40974d55 0xE69A8A6cD11D46BE328F4d6b211032f836f89743 0x8076Df8a93F39C4A059A7993044955Ff03Ed612b 1794828800) contracts/distribution/HogGenesisRewardPool.sol:HogGenesisRewardPool --chain 11155111 --watch


deploy-hog-base:
	forge create --broadcast --rpc-url $BASE_URL --account baseman contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT

verify-hog-base:
	

    forge verify-contract 0xb3B1fBEE53732174fE9Eca63d76660CA40974d55 --constructor-args $(cast abi-encode "constructor(address,address)" 0x96669d5f2220ab06de30e609563660a1e6c8408a 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) contracts/HOG.sol:HOG --chain 84532 --watch

