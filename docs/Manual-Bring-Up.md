# Manual Bring-Up (Local & AWS EC2)

## Services to start (minimal)
- Config Server (8888)
- Discovery/Eureka (8761)
- Customers, Vets, Visits (random ports)
- API Gateway + UI (8080)

## Local (Java)
See repository README for steps using `./mvnw ...`.

## AWS EC2 (Ubuntu)
- Instance type: t3.large
- Open ports (temporarily from your IP): 8080, 8761
