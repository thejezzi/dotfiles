CONTAINER_RT ?= podman
IMAGE        ?= dotfiles-test:latest

.PHONY: test test-container image clean-image

## Run the smoke test in a fresh fedora:latest container
test: test-container

test-container: image
	$(CONTAINER_RT) run --rm \
	  -e HOME=/tmp/fakehome \
	  -v "$(CURDIR):/dotfiles:ro,z" \
	  $(IMAGE)

## Build (or rebuild) the test image
image:
	$(CONTAINER_RT) build -t $(IMAGE) -f Containerfile.test .

## Remove the test image
clean-image:
	$(CONTAINER_RT) rmi $(IMAGE) 2>/dev/null || true
