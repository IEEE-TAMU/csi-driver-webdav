# Nix builder
FROM nixos/nix:latest AS builder

# Copy our source and setup our working dir.
COPY . /tmp/build
WORKDIR /tmp/build

# Build our Nix environment
RUN nix \
    --extra-experimental-features "nix-command flakes" \
    --option filter-syscalls false \
    build

# Copy the Nix store closure into a directory. The Nix store closure is the
# entire set of Nix store values that we need for our build.
RUN mkdir /tmp/nix-store-closure
RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure

# we also need davfs2 and I'm struggling to get it to work in a pure nix environment
# this step means we likely have 2 versions (nix store and debian) versions of lots of things
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y davfs2 ca-certificates
RUN ln -s /proc/mounts /etc/mtab

WORKDIR /app

# Copy /nix/store
COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /tmp/build/result /app
ENTRYPOINT ["/app/bin/webdav"]