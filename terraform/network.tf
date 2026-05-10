# ----------------------------------------------------------------------------
# Networking — a single VPC with one public subnet.
# Single-AZ keeps the free-tier story simple. Multi-AZ would mean two subnets
# and a NAT gateway ($30/mo), so we punt on it for this project.
# ----------------------------------------------------------------------------

# `data` blocks query existing AWS resources. We don't create AZs — AWS owns
# them — but we want their names to place the subnet in one.
data "aws_availability_zones" "available" {
  state = "available"
}

# The VPC itself — a private network in AWS, isolated from other VPCs.
# CIDR 10.0.0.0/16 gives us 65,536 addresses to play with.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true # so EC2 instances get DNS names like ip-10-0-1-x.ec2.internal

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway — the thing that gives the VPC outbound internet access.
# Without this, EC2 instances can't reach api.github.com to install k3s.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public subnet — instances launched here get public IPs and can reach the
# internet through the IGW. We pick the first AZ from the data source.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route table — instructions for "where does traffic to X go?".
# We add one rule: anything not local goes out the IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Tells the subnet to use the route table above. Without this association,
# the subnet would use the VPC's "main" route table (no IGW route, no internet).
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
