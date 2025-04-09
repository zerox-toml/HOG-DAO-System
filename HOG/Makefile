deploy-hog:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT

deploy-hog-cronos:
	forge create --broadcast --rpc-url $CRONOS_URL --private-key $PRIVATE_KEY contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT

verify-hog:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0xD2a3d41d2c01426C53d4e272f231133f167b2C87 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0xa54b32E8432d5908c2f44e88d54Ba52835e7377b \
    contracts/HOG.sol:HOG

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
	forge create --broadcast --rpc-url $BASE_URL --account spectre contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT

verify-hog-base:
	forge verify-contract \
    --chain-id 84532 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0xD2a3d41d2c01426C53d4e272f231133f167b2C87 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) \
    --verifier-url https://api-testnet.cronoscan.com/QsE9DiSy4CWOJpMpowvc6LoYZFvlalBY \
    --compiler-version v0.8.19 \
    0x80bbD9699Be5fc7e6e1c8E477792840afAD74CCF \
    contracts/HOG.sol:HOG