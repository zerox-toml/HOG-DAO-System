# sepolia
deploy-oracle:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/Oracle.sol:Oracle --constructor-args $POOL_ADDRESS
    
# sepolia
deploy-mock-pool:
	
    forge create --broadcast contracts/mocks/MockPool.sol:MockPool --rpc-url $SEPOLIA_URL --account baseman --constructor-args $TOKEN0_ADDRESS $TOKEN1_ADDRESS $RESERVE0 $RESERVE1
    forge create --broadcast contracts/mocks/MockPool.sol:MockPool --rpc-url $SEPOLIA_URL --account baseman --constructor-args $HOG_ADDRESS $WETH_ADDRESS 1000 1000
    forge create --broadcast contracts/mocks/MockPool.sol:MockPool --rpc-url $SEPOLIA_URL --account baseman --constructor-args $GHOG_ADDRESS $WETH_ADDRESS 1000 1000
# 0xcB75395eE9b6551426Fe9ED334A284b6A3BF4113

deploy-oracle:
    forge create --broadcast contracts/Oracle.sol:Oracle --rpc-url $SEPOLIA_URL --account baseman --constructor-args $POOL_ADDRESS
#  base-sepolia
deploy-mockpool-base:
    forge create --broadcast contracts/mocks/MockPool.sol:MockPool --rpc-url $BASE_SEPOLIA_RPC --account baseman --constructor-args $TOKEN0_ADDRESS $TOKEN1_ADDRESS $RESERVE0 $RESERVE1
#  0x74b4A3FBa600f3e9EB95d95aBd1AF22cDaE73841

verify-mockpool-base:
    forge verify-contract 0x74b4A3FBa600f3e9EB95d95aBd1AF22cDaE73841 --constructor-args $(cast abi-encode "constructor(address,address,uint112,uint112)" 0xe15cf0f8faed96dce0e09173c03f2f0192ab4d17 0xb37e29527941191bca11fbb696af8e257cccd49d 1000000 1000000) contracts/mocks/MockPool.sol:MockPool --chain 84532 --watch 

deploy-oracle-base:
    forge create --broadcast contracts/Oracle.sol:Oracle --rpc-url $SEPOLIA_URL --account baseman --constructor-args $POOL_ADDRESS_HOG_WETH
# 0x96669D5F2220ab06De30E609563660A1e6C8408a

verify-oracle-base:
    forge verify-contract 0x96669D5F2220ab06De30E609563660A1e6C8408a --constructor-args $(cast abi-encode "constructor(address)" 0x74b4A3FBa600f3e9EB95d95aBd1AF22cDaE73841)  contracts/Oracle.sol:Oracle --chain 84532 --watch 








    