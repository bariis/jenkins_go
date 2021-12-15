#FROM golang:1.16-alpine AS build-env
#RUN mkdir /go/src/app && apk update && apk add git && go mod init github.com/bariis/jenkins_go
#ADD main.go /go/src/app/
#RUN go mod init github.com/bariis/jenkins_go
#WORKDIR /src
#COPY . .
#RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o app .
#RUN go build -o /bin/app .

#ENTRYPOINT ["/bin/app"]

#FROM scratch
#WORKDIR /app
#COPY --from=build-env /go/src/app/app .
#ENTRYPOINT [ "./app" ]


#FROM golang:1.16-alpine AS build-env
#RUN mkdir /go/src/app && apk update && apk add git && go mod init github.com/bariis/jenkins_go
#ADD main.go /go/src/app/
#WORKDIR /go/src/app
#RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o app .

#FROM scratch
#WORKDIR /app
#COPY --from=build-env /go/src/app/app .
#ENTRYPOINT [ "./app" ]

FROM golang:alpine as builder

# Set the current working directory inside the container
WORKDIR /app

# Copy go mod and sum files
#COPY go.mod go.sum ./

# Download all dependencies
#RUN go mod download

# Copy source from current directory to working directory
COPY . .

# Build the application
ENV GO111MODULE=auto

RUN CGO_ENABLED=0 GOOS=linux go build -a -o main .

FROM alpine:latest

RUN apk --no-cache add ca-certificates

# Set the current working directory inside the container
WORKDIR /root

# Copy the binary executable over
COPY --from=builder /app/main .
COPY --from=builder /app/.env .

# Expose necessary port
EXPOSE 8085

# Run the created binary executable 
CMD ["./main"]
