deploy-masonry-sepolia:
	forge create --broadcast --rpc-url $SEPOLIA_URL --private-key $PRIVATE_KEY contracts/Masonry.sol:Masonry --constructor-args $HOG_ADDRESS $GHOG_ADDRESS 20000 400000000

verify-masonry-sepolia:
	forge verify-contract \
		--chain-id 11155111 \
		--num-of-optimizations 200 \
		--watch \
		--constructor-args $(cast abi-encode "constructor(address,address,uint256,uint256	)" 0xa54b32E8432d5908c2f44e88d54Ba52835e7377b 0x008769eE2D69B2B7da69d04fD1dbD17CFC3353b3 20000 400000000) \
		--etherscan-api-key 6XJ6B1342MD2S4H1H3HTPVJ7Y2BZ6J7269 \
		--compiler-version v0.8.19 \
			0x5AE18C019422496f5814c1b39bE96961705473c8 \
		contracts/Masonry.sol:Masonry			