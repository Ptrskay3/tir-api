# Build Stage
FROM rust:1.65.0 as builder

RUN USER=root cargo new --bin tir-engine
WORKDIR ./tir-engine
COPY ./Cargo.toml ./Cargo.toml
# Build empty app with downloaded dependencies to produce a stable image layer for next build
RUN cargo build --release

# Build web app with own code
RUN rm src/*.rs
ADD . ./
RUN rm ./target/release/deps/axum_demo*
RUN cargo build --release


FROM debian:buster-slim
ARG APP=/usr/src/app

RUN apt-get update \
    && apt-get install -y ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 3000

ENV TZ=Etc/UTC \
    APP_USER=appuser

RUN groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP}

COPY --from=builder /tir-engine/target/release/tir-engine ${APP}/tir-engine
COPY --from=builder /tir-engine/static ${APP}/static

RUN chown -R $APP_USER:$APP_USER ${APP}

USER $APP_USER
WORKDIR ${APP}

CMD ["./tir-engine"]