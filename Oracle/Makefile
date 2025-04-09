# sepolia
deploy-oracle:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/Oracle.sol:Oracle --constructor-args $POOL_ADDRESS

# sepolia
deploy-mock-pool:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/mocks/MockPool.sol:MockPool --constructor-args $TOKEN0_ADDRESS $TOKEN1_ADDRESS $RESERVE0 $RESERVE1

verify-oracle:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address)" 0x321f1F0139a463b0b12127FD0A44a77113af030a ) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0xbF1a9a0Fc64aC1180b83db96E48D4aDCC54C99B9 \
    contracts/Oracle.sol:Oracle

verify-mock-pool:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address,uint112,uint112)" 0xAFCeF4f09e89B157A7eC2A2885e801A1b4D9C9bC 0x87D19f9a5DFe56CBb6803ACd1d9D7536eddaa7a4 500 5000) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0x60229B61BC725f6F181926910b58CC10a3323662 \
    contracts/mocks/MockPool.sol:MockPool


#  base-sepolia
deploy-mockpool-base:
    forge create --broadcast contracts/mocks/MockPool.sol:MockPool --rpc-url $BASE_SEPOLIA_RPC --account baseman --constructor-args $TOKEN0_ADDRESS $TOKEN1_ADDRESS $RESERVE0 $RESERVE1
#  0x74b4A3FBa600f3e9EB95d95aBd1AF22cDaE73841

verify-mockpool-base:
    forge verify-contract 0x74b4A3FBa600f3e9EB95d95aBd1AF22cDaE73841 --constructor-args $(cast abi-encode "constructor(address,address,uint112,uint112)" 0xe15cf0f8faed96dce0e09173c03f2f0192ab4d17 0xb37e29527941191bca11fbb696af8e257cccd49d 500 5000) contracts/mocks/MockPool.sol:MockPool --chain 84532 --watch 

deploy-oracle-base:
    forge create --broadcast contracts/Oracle.sol:Oracle --rpc-url $BASE_SEPOLIA_RPC --account baseman --constructor-args $POOL_ADDRESS
# 0x96669D5F2220ab06De30E609563660A1e6C8408a

verify-oracle-base:
    forge verify-contract 0x96669D5F2220ab06De30E609563660A1e6C8408a --constructor-args $(cast abi-encode "constructor(address)" 0x74b4A3FBa600f3e9EB95d95aBd1AF22cDaE73841)  contracts/Oracle.sol:Oracle --chain 84532 --watch 








    