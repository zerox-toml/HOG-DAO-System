deploy-sepolia:
	forge create contracts/Treasury.sol:Treasury --account baseman --rpc-url $SEPOLIA_URL --broadcast --constructor-args $HOG_ADDRESS


deploy-sepolia-script:
	forge script script/Treasury.s.sol:DeployTreasury --rpc-url $SEPOLIA_URL --broadcast --private-key $PRIVATE_KEY



deploy-treasury-base:
    forge create --broadcast --rpc-url $BASE_URL --account baseman contracts/Treasury.sol:Treasury --constructor-args $HOG_ADDRESS
# 0x29A3602FaeB0f2F9D18307FCD612D4588f2De010

verify-treasury-base:
    forge verify-contract 0xa8D79cC7C889c33cBa84184962002d593Df0e642 --constructor-args $(cast abi-encode "constructor(address)"  0xb3B1fBEE53732174fE9Eca63d76660CA40974d55) contracts/Treasury.sol:Treasury --chain 11155111 --watch
