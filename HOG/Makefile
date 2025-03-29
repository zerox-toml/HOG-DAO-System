deploy-hog:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/HOG.sol:HOG --constructor-args $ORACLE_ADDRESS $TAX_RECIPIENT

verify-hog:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0xD2a3d41d2c01426C53d4e272f231133f167b2C87 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0xA5fA5731CfCCC7e7DBD202579D3B1F6ee78403E9 \
    contracts/HOG.sol:HOG