# 3. IAM Role for EC2 to access the secret
resource "aws_iam_role" "ec2_role" {
  for_each = var.instance_profiles
  name = format("%s_%s_ec2-secret-access-role", local.common_prefix, each.key)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    {
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }
    # ,
    # {
    #   Effect = "Allow"
    #   Principal = {
    #     Service = "s3:amazonaws.com"
    #   }
    #   # Resource = format("arn:aws:s3:::%s", aws_s3_bucket.bucket["berthillon-bucket"].bucket)
    #   Action = "s3:ListBucket"
    # },
    # {
    #   Effect = "Allow"
    #   Principal = {
    #     Service = "s3:amazonaws.com"
    #   }
    #   # Resource = format("arn:aws:s3:::%s", aws_s3_bucket.bucket["berthillon-bucket"].bucket)
    #   Action = [
    #     "s3:GetObject",
    #     "s3:PutObject",
    #     "s3:PutObjectAcl"
    #   ]
    # }
    ]
  })
}

# 6. Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  for_each = var.instance_profiles
  name = format("%s_%s_ec2-instance-profile", local.common_prefix, each.key)
  role = aws_iam_role.ec2_role[each.key].name
}