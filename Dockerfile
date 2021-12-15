FROM golang:1.16-alpine AS build-env
RUN mkdir /go/src/app && apk update && apk add git && go mod init github.com/bariis/jenkins_go
ADD main.go /go/src/app/
WORKDIR /go/src/app
#RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o app .
RUN go build -o app .

FROM scratch
WORKDIR /app
COPY --from=build-env /go/src/app/app .
ENTRYPOINT [ "./app" ]
