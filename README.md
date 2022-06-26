# awesome_challenge_terraform_fargate
The goal of this project is to auto provision an infrastructure consisting of a single ECS cluster with two separate tasks.
- Fist task would include the server container which is an simple socat server listening on TCP:5555 and would respond with a 'pong' message on each call.
- Second task would include the client container which also is made of the same socat image and would be using socat to call the server container on port 5555

### Challenges faced:
- To keep the containers light and easily debuggable I have used the alpine/socat container and the first challenge was to figure out how to create a client/server application with socat.
- Private VPC + ECS didn't work and Docker Image Pull failed on the tasks initially so I had to create a separate public subnet on the VPC and attach a NAT gateway to resolve this issue while keeping the private services secure.


How to run:

## On linux:
- load your aws keys:
```shell
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```

initiallize terraform:
```shell
terraform init
```

```shell
terraform apply
```