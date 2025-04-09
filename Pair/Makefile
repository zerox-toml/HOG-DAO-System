deploy-pair:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/Pair.sol:Pair --constructor-args $HOG_ADDRESS $WETH_ADDRESS

verify-pair:
	forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0xD2a3d41d2c01426C53d4e272f231133f167b2C87 0xa9C9c76287d603A5Eb28eC059df2b959fDE9AB22) \
    --etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
    --compiler-version v0.8.19 \
    0x0000000000000000000000000000000000000000 \
    contracts/Pair.sol:Pair