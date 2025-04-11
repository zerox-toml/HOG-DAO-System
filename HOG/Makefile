deploy-hog:
	forge create --broadcast --rpc-url $SEPOLIA_URL --account baseman contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT
# 0xb3B1fBEE53732174fE9Eca63d76660CA4

verify-hog:
    forge verify-contract 0xb3B1fBEE53732174fE9Eca63d76660CA40974d55 --constructor-args $(cast abi-encode "constructor(address,address)" 0xF921b7c44D850282985a200d538015E21f737d6C 0xaa8e23fb1079ea71e0a56f48a2aa51851d8433d0) contracts/HOG.sol:HOG --chain 11155111 --watch

deploy-hog-cronos:
	forge create --broadcast --rpc-url $CRONOS_URL --private-key $PRIVATE_KEY contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT



verify-hog-cronos:
	forge verify-contract \
    --chain-id 338 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0xD2a3d41d2c01426C53d4e272f231133f167b2C87 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) \
    --verifier-url https://api-testnet.cronoscan.com/QsE9DiSy4CWOJpMpowvc6LoYZFvlalBY \
    --compiler-version v0.8.19 \
    0x80bbD9699Be5fc7e6e1c8E477792840afAD74CCF \
    contracts/HOG.sol:HOG

deploy-hog-base:
	forge create --broadcast --rpc-url $BASE_URL --account baseman contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT

verify-hog-base:
	

    forge verify-contract 0xb3B1fBEE53732174fE9Eca63d76660CA40974d55 --constructor-args $(cast abi-encode "constructor(address,address)" 0x96669d5f2220ab06de30e609563660a1e6c8408a 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) contracts/HOG.sol:HOG --chain 84532 --watch

