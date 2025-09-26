# zig-code-coverage
Example repo that show how to generate code coverage in Zip

# Testing with docker

``` bash
docker buildx create --name insecure-builder --buildkitd-flags "--allow-insecure-entitlement security.insecure"
docker buildx build --platform "linux/amd64,linux/arm64"  --progress plain  --builder insecure-builder --allow security.insecure --tag test . 
```