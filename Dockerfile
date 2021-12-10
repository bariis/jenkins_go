FROM golang:1.16
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/app

FROM scratch
COPY --from=0 /bin/app /bin/app
ENTRYPOINT ["/bin/app"]

