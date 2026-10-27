FROM alpine:3.24 AS builder

RUN apk add --no-cache zig
WORKDIR /app
COPY . .

RUN zig build -Doptimize=ReleaseFast

#----------------------------------------------------

FROM scratch
COPY --from=builder /app/zig-out/bin/png2til /png2til

ENTRYPOINT ["/png2til"]
