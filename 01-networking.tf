# To create a basic IP filtering to the entry points,
# fill in your IP through command line:
# terraform plan -var="operator-ip=184.168.131.241/32"
variable "operator-ip" {
  type = string
  # default = "0.0.0.0/0"
}

# The number of available IPs are set to the minimal value here.
# 16 IPs are available per subnet.
variable "cidr_blocks" {
  default = {
    global    = "0.0.0.0/0"
    vpc       = "192.168.0.0/21"
    private_1 = "192.168.1.0/28"
    private_2 = "192.168.2.0/28"
    public_1  = "192.168.3.0/28"
    public_2  = "192.168.4.0/28"
  }
}

variable "availability_zones" {
  type    = list(string)
  default = ["a", "b"]
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_blocks.vpc
}

resource "aws_subnet" "privates" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.cidr_blocks[format("private_%s", count.index + 1)]
  availability_zone       = format("%s%s", var.aws_region, element(var.availability_zones, count.index))
  map_public_ip_on_launch = false
}

resource "aws_subnet" "publics" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.cidr_blocks[format("public_%s", count.index + 1)]
  availability_zone       = format("%s%s", var.aws_region, element(var.availability_zones, count.index))
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_base" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = var.cidr_blocks["global"]
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = element(aws_subnet.publics.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "this" {
  vpc = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = element(aws_subnet.publics.*.id, 0)
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.cidr_blocks["global"]
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = element(aws_subnet.privates.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
